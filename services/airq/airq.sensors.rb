#############################################################################################################
## AirQ sensor service ######################################################################################
#############################################################################################################
require 'sinatra'

class CitySDK_Services < Sinatra::Base
  AIRQ_HOST = "http://wg66.waag.org"
  AIRQ_PORT = "8090"
  AIRQ_PATH = "/lastsensordata"
  AIRQ_TIMEOUT = 5
  AIRQ_KEYPREFIX = "airq.sensors"
  #AIRQ_LAT = :lat
  #AIRQ_LON = :lon

  # curl --data '{"id":"CE-P01 Sloterdijk"}' http://localhost:9292/parking
  post '/airq' do

    # Read data from request
    json = self.parse_request_json
    id = json['id']
    jsonlog(json)

    # TODO: naming convention!
    key = "#{AIRQ_KEYPREFIX}!!#{id}"
    data = CitySDK_Services.memcache_get(key)

    if not data || data == {}
      connection = Faraday.new "#{AIRQ_HOST}:#{AIRQ_PORT}"
      response = self.httpget(connection, AIRQ_PATH)

      if response.status == 200
        sensors = JSON.parse(response.body,symbolize_names: true)
        jsonlog(sensors)
        sensors.each do |sensor|
          sensor_key = "#{AIRQ_KEYPREFIX}!!#{sensor[:id]}"
          #sensor.delete("#{AIRQ_LAT}")
          #sensor.delete("#{AIRQ_LON}")
          # Convert number in properties hash to integers
          # TODO: get timeout from layer data
          CitySDK_Services.memcache_set(sensor_key, sensor, AIRQ_TIMEOUT)
        end
      end

      # If requested CitySDK node does not exist in sensors
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
