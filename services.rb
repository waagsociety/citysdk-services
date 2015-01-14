# encoding: utf-8
require 'faraday'
require 'sinatra'
require 'json'
require "i18n"
require 'active_support/core_ext'

require './utils.rb'

# Require all .rb files in services subdirs
Dir[File.dirname(__FILE__) + '/services/*/*.rb'].each {|file| require file }

configure do | sinatraApp |
  set :environment, :production  
  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        # We're in smart spawning mode.
        CitySDK_Services.memcache_new  
      end
      # Else we're in direct spawning mode. We don't need to do anything.
    end
  end   
end

class CitySDK_Services < Sinatra::Base
  def do_abort(code, message)
    throw(:halt, [code.to_json, {'Content-Type' => 'application/json'}, message])
  end
    
  after do
    content_type 'application/json'
  end

  def parse_request_json
    begin  
      return JSON.parse(request.body.read)
    rescue => exception
      self.do_abort(422, {result: "fail", error: "Error parsing JSON", message: exception.message})
    end
  end
  
  def httpget(connection, path)
    $stderr.puts "in httpget"
    
    response = ''
    begin
      response = connection.get do |req|
        req.url path
        req.options[:timeout] = 5
        req.options[:open_timeout] = 2
      end
    rescue Exception => e
      self.do_abort(408, {result: "fail", error: "Error requesting resource.", message: e.message})
    end
    
    $stderr.puts response
    
    return response
  end

  get '/' do
    { :status => 'success', 
      :url => request.url, 
    }.to_json 
  end
  
end