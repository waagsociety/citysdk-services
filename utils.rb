require 'dalli'


class CitySDK_Services < Sinatra::Base
      
  # TODO: partly copied from citysdk.git/server/utils/api_utils.rb.
  
  ##########################################################################################
  # memcache utilities
  ##########################################################################################
  
  # To flush local instance of memcached:
  #   echo 'flush_all' | nc localhost 11211
  
  def self.memcache_new
    @@memcache = Dalli::Client.new('localhost:11211')
  end
  
  @@memcache = Dalli::Client.new('localhost:11211')

  def self.memcache_get(key)
    begin
      return @@memcache.get(key)
    rescue
      begin
        @@memcache = Dalli::Client.new('localhost:11211')
      rescue
        $stderr.puts "Failed connecting to memcache: #{e.message}\n\n"
        @@memcache = nil
      end
    end
  end
  
  def self.memcache_set(key, value, ttl=300)
    begin      
      return @@memcache.set(key,value,ttl)
    rescue
      begin
        @@memcache = Dalli::Client.new('localhost:11211')
      rescue
        $stderr.puts "Failed connecting to memcache: #{e.message}\n\n"
        @@memcache = nil
      end
    end
  end
  
end

def jsonlog(o) # debugging
  File.open("/var/www/_services/log/debug.log","a") do |fd|
        fd.puts JSON.pretty_generate({ o.class.to_s => o })
  end
end
