### CitySDK Amsterdam webservices

####What:

Services that are hosted here act as 'glue' between the LD API and external (mostly real-time) web services. The idea is that thr current data packet is provided, the code in the glue service uses this data for a request with the external service, and returns a new data packet, based on the old packet and the response from the external service.
Results are ususally cached (using memcached) to reduce the number of external requests..

#### Boilerplate code

    class CitySDK_Services < Sinatra::Base
     
      EXT_API_KEY = File.open(File.dirname(__FILE__) + '/key.txt','r').read
      
      post '/service' do
      
        # Read data from request 
        json = self.parse_request_json
        
        # json is the current data from CitySDK node
        id = json["id"]
        
        memcache_key = "service!!#{id}"
        data = CitySDK_Services.memcache_get(memcache_key)
        if not data
          connection = Faraday.new "http://exernal_service.org"
          response = self.httpget(connection, "/api/#{id}?key=#{EXT_API_KEY}")
        
          if response.status == 200
          
            return { 
              :status => 'success', 
              :url => request.url, 
              :data => JSON.parse(response)
            }.to_json 
          else
            self.do_abort(response.status, {result: "fail", error: "Error requesting resource", message: exception.message})
          end
        end

      end
    end  
      
