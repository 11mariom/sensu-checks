#!/opt/sensu/embedded/bin/ruby
#  encoding: UTF-8
#
#   check-postgres-replication
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: pg
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 11mariom
#   Released under GPLv2; see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'pg'
require 'time'

class CheckPGReplication < Sensu::Plugin::Check::CLI
  option :user,
    description: 'PostgreSQL user',
    short: '-u USER',
    long: '--user USER',
    default: "postgres"

  option :password,
    description: 'PostgreSQL password',
    short: '-P PASS',
    long: '--password PASS'

  option :host,
    description: 'IP of PostgreSQL host_1',
    short: '-h HOST',
    long: '--host HOST',
    default: "127.0.0.1"

  option :port,
    description: 'Port of PostgreSQL',
    short: '-p PORT',
    long: '--port PORT',
    default: "5432"

  option :masterhost,
    description: 'IP of PostgreSQL host_2',
    short: '-H HOST',
    long: '--master-host HOST'

  def is_slave(pg)
    query = "SELECT pg_is_in_recovery();"
    pg.exec(query) do |result|
      if result[0]["pg_is_in_recovery"] == 't'
        true
      else
        false
      end
    end
  end

  def location(pg)
    loc = Hash.new(0)
    if is_slave(pg)
      query = "SELECT pg_last_xlog_receive_location(), pg_last_xlog_replay_location(), pg_last_xact_replay_timestamp();"
    else
      query = "SELECT pg_current_xlog_location();"
    end

    pg.exec(query) do |result|
      result.each do |row|
        row.each do |k, v|
          case k
          when "pg_last_xlog_receive_location" then
            loc["location"] = v
          when "pg_last_xlog_replay_location" then
            loc["replay"] = v
          when "pg_current_xlog_location" then
            loc["location"] = v
          when "pg_last_xact_replay_timestamp" then
            loc["timestamp"] = v 
          end
        end
      end
    end

    loc
  end

  def diff(a, b)
    a = a.gsub(/\d+\//, '').hex
    b = b.gsub(/\d+\//, '').hex

    return (a-b).abs
  end

  def run
    master = PG::Connection.new(config[:masterhost], config[:port], nil, nil, 'postgres',
     config[:user], config[:password])
    slave  = PG::Connection.new(config[:host], config[:port], nil, nil, 'postgres',
     config[:user], config[:password])

    if is_slave(slave)
      lm = location(master)
      ls = location(slave)
    else
      lm = location(slave)
      ls = location(master)
    end

    if ls['timestamp'] != nil
      tdiff = Time.now().to_i - Time.parse(ls['timestamp']).to_i
    else
      tdiff = 999999999
    end

    ldiff = diff(lm['location'], ls['location'])

    message "master (#{config[:masterhost]}): #{lm['location']}, slave (#{config[:host]}): #{ls['location']}:#{ls['replay']}, diff: #{ldiff}, time: #{ls['timestamp']} (#{tdiff} seconds off)"
    critical if (lm["location"] != ls["replay"] && ldiff > 152 && tdiff > 60)
    warning  if (lm["location"] != ls["location"] && tdiff > 60)
    ok
  end
end
