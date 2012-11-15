#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require 'eventmachine'
require 'terminal-notifier'
require 'em-http'
require 'json'
require "net/https"
require "uri"

token = ''
organization = ''
flow = ''

uri = URI.parse("https://api.flowdock.com/v1/flows/#{organization}/#{flow}/users")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth(token, "")
response = http.request(request)
users = JSON.parse(response.body).reduce({}) {|memo, u| memo[u['id']] = u; memo }


http = EM::HttpRequest.new("https://stream.flowdock.com/flows/#{organization}/#{flow}")

EventMachine.run do
  s = http.get(:head => { 'Authorization' => [token, ''], 'accept' => 'application/json'}, :keepalive => true, :connect_timeout => 0, :inactivity_timeout => 0)

  buffer = ""
  s.stream do |chunk|
    buffer << chunk
    while line = buffer.slice!(/.+\r\n/)
      message = JSON.parse(line)
      TerminalNotifier.notify(message['content'], :title => 'Flowdock', :subtitle => "#{users[message['user'].to_i]['name']} wrote:")
    end
  end
end