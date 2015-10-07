#############################################################################################################
## Parking garage capacity ##################################################################################
#############################################################################################################

class CitySDK_Services < Sinatra::Base
  PARKING_HOST = "http://opd.it-t.nl"
  PARKING_PATH = "/data/amsterdam/ParkingLocation.json"
  PARKING_TIMEOUT = 5 * 60
 

# http://opd.it-t.nl/data/amsterdam/ParkingLocation.json
 
  #PARKING_MAPPING = JSON.parse(File.open(File.dirname(__FILE__) + '/mapping.json','r').read)
  
  # curl --data '{"id":"CE-P01 Sloterdijk"}' http://localhost:9292/parking  
  post '/parking' do
    
    # Read data from request 
    json = self.parse_request_json
    id = json["id"]
   
    # TODO: naming convention!
    key = "parking!!#{id}"
    data = CitySDK_Services.memcache_get(key)

    if not data || data == {}
      connection = Faraday.new PARKING_HOST    
      response = httpget(connection, PARKING_PATH)
      if response.status == 200
        garages = JSON.parse response.body
        garages["features"].each do |garage|
          id = garage["properties"]["Name"]          
          garage_key = "parking!!#{id}"
          # Convert number in properties hash to integers
          garage["properties"]["FreeSpaceShort"] = garage["properties"]["FreeSpaceShort"].to_i
          garage["properties"]["FreeSpaceLong"] = garage["properties"]["FreeSpaceLong"].to_i
          garage["properties"]["ShortCapacity"] = garage["properties"]["ShortCapacity"].to_i
          garage["properties"]["LongCapacity"] = garage["properties"]["LongCapacity"].to_i
            
          # TODO: get timeout from layer data
          CitySDK_Services.memcache_set(garage_key, garage["properties"], PARKING_TIMEOUT)       
        end
      end
      
      # If requested CitySDK node does not exist in parking API/mapping
      # Set key to empty hash, to prevent fetching URL next time again
      data = CitySDK_Services.memcache_get(key)
      if not data
        data = {}
      end      
    
    end    
    
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => data
    }.to_json 

  end
end 
