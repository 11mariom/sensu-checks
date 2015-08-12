#! /opt/sensu/embedded/bin/ruby
#
#   metrics-unifi.rb
#
# DESCRIPTION:
#   This plugin collects metrics from a Unifi wireless controller
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   metrics-unifi.rb
#
# NOTES:
#
#
# LICENSE:
#   Copyright Eric Heydrick <eheydrick@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

# Collect unifi metrics
class UnifiMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.unifi"

  option :hostname,
         description: 'Unifi AP controller hostname',
         short: '-h HOSTNAME',
         long: '--hostname HOSTNAME',
         default: 'unifi'

  option :username,
         description: 'Username',
         short: '-u USERNAME',
         long: '--username USERNAME',
         default: 'unifi'

  option :password,
         description: 'Password',
         short: '-p PASSWORD',
         long: '--password PASSWORD'

  option :path,
         description: 'Path to unifi-get-stats.py',
         short: '-i PATH',
         default: '/usr/local/bin'

  def unifi_stats
    `#{config[:path]}/unifi-get-stats.py -c #{config[:hostname]} -u #{config[:username]} -p #{config[:password]}`
  end

  def run
    unifi = JSON.parse(unifi_stats)
    unifi.each do |metric, value|
      value.each do |k,v|
      	output "#{config[:scheme]}.#{metric.gsub(/\s\(#.\)/, "").gsub(/\s+/,"_").downcase()}.#{k}", v
      end
    end
    ok
  end
end
