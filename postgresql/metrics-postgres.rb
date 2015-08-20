#!/opt/sensu/embedded/bin/ruby
#  encoding: UTF-8
#
#   metrics-postgres
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

require 'sensu-plugin/metric/cli'
require 'socket'
require 'pg'

class PostgresStatus < Sensu::Plugin::Metric::CLI::Graphite
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
    description: 'IP of squid host',
    short: '-h HOST',
    long: '--host HOST',
    default: "127.0.0.1"

  option :port,
    description: 'Port of squid host',
    short: '-p PORT',
    long: '--port PORT',
    default: "5432"

  option :scheme,
    description: 'Metric naming scheme',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}.postgres"

  def locks
    locks_per_type = Hash.new(0)
    query = 'SELECT mode, count(mode) FROM pg_locks group by mode'

    @psql.exec(query) do |result|
      result.each do |row|
        lock_name = row['mode'].downcase.to_sym
        locks_per_type[lock_name] += 1
      end
    end

    locks_per_type.each do |lock_type, count|
      output "#{config[:scheme]}.locks.#{lock_type}", count
    end
  end

  def connections
    query = 'SELECT count(*), waiting from pg_stat_activity group by waiting'

    metrics = {
      active: 0,
      waiting: 0
    }

    @psql.exec(query) do |result|
      result.each do |row|
        if row['waiting']
          metrics[:waiting] = row['count']
        else
          metrics[:active] = row['count']
        end
      end
    end

    metrics.each do |metric, value|
      output "#{config[:scheme]}.connections.#{metric}", value
    end
  end

  def run
    @psql = PG::Connection.new(config[:host], config[:port], nil, nil, 'postgres',
     config[:user], config[:password])

    locks
    connections

    ok
  end
end
