#!/opt/sensu/embedded/bin/ruby
#  encoding: UTF-8
#
#   metrics-squid
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

class SquidStatus < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
    description: 'IP of squid host',
    short: '-h HOST',
    long: '--host HOST',
    default: "127.0.0.1"

  option :port,
    description: 'Port of squid host',
    short: '-p PORT',
    long: '--port PORT',
    default: "80"

  option :scheme,
    description: 'Metric naming scheme',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}.squid"

  def run
    mgr_info = `squidclient -h #{config[:host]} -p #{config[:port]} mgr:info`

    mgr_info.scan(/\s+([\w %\(\)]+):\s+(\d+[\.\d]*)/) do |name, value|
      case name
        when "Number of clients accessing cache" then
          output "#{config[:scheme]}.clients", value
        when "Number of HTTP requests received" then
          output "#{config[:scheme]}.http_requests", value
        when "Request failure ratio" then
          output "#{config[:scheme]}.req_fail_ratio", value
        when "Average HTTP requests per minute since start" then
          output "#{config[:scheme]}.avg_http_req_per_min", value
        when "Hits as % of all requests" then
          output "#{config[:scheme]}.request_hit_ratio", value
        when "Hits as % of bytes sent" then
          output "#{config[:scheme]}.byte_hit_ratio", value
        when "Storage Swap size" then
          output "#{config[:scheme]}.cache_size_disk", value
        when "Storage Mem size" then
          output "#{config[:scheme]}.cache_size_mem", value
        when "HTTP Requests (All)" then
          output "#{config[:scheme]}.servicetime_httpreq", value
      end
    end
    if (mgr_info.lines.first !~ /200 OK/) then
      critical "Squid not running on #{config[:host]}:#{config[:port]}"
    end
    ok
  end
end
