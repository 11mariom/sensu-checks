#!/opt/sensu/embedded/bin/ruby
#
# Sensu Handler: smsapi
#
# username - you're smsapi.pl username
# password - md5 of API password
# from - Eco, 2way or 'name'

require 'sensu-handler'
require 'uri'
require 'net/http'
require 'net/https'

class Smsapi < Sensu::Handler
  option :json_config,
    description: 'Config name',
    short: 'j JsonConfig',
    long: '--json_config JsonConfig',
    required: false

  def action_to_string
    @event['action'].eql?('resolve') ? 'RESOLVED' : 'ALERT'
  end

  def status_to_string
    case @event['check']['status']
    when 0
      'OK'
    when 1
      'WARNING'
    when 2
      'CRITICAL'
    else
      'UNKNOWN'
    end
  end

  def send_sms
    uri = URI.parse(@url)
    data = {
      "username" => @username,
      "password" => @password,
      "from" => @from,
      "to" => @to,
      "message" => @message,
      "test" => @test == 'true' ? 1 : 0
    }.map{|k,v| "#{k}=#{v}"}.join('&')
    data = URI::encode(data)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new("#{uri.request_uri}/sms.do?#{data}")
    response = http.request(request)
    puts "#{data}"
    puts "#{response.body}"
  end

  def handle
    json_config = config[:json_config] || 'smsapi'
    @url = "https://api.smsapi.pl"
    @username = settings[json_config]['username']
    @password = settings[json_config]['password']
    @from = settings[json_config]['from']
    @to = settings[json_config]['to']
    @test = settings[json_config]['test'] || false

    @message = "#{action_to_string} #{@event['client']['name']} - #{status_to_string}: #{@event['check']['name']}"
    send_sms
    puts "#{@message}"
  end
end
