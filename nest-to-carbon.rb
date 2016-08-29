#!/usr/bin/env ruby

require 'nest_thermostat'
require 'simple-graphite'

nest = NestThermostat::Nest.new(email: ENV['NEST_EMAIL'], password: ENV['NEST_PASS'])
g = Graphite.new({:host => ENV['GRAPHITE_HOST'], :port => ENV['GRAPHITE_PORT']})

def convert_temp(temp)
  new_temp = temp.to_f * 9.0 / 5 + 32.round(5).to_i
  return new_temp
end

status=nest.status

weather_url='https://apps-weather.nest.com/weather/v1?query='

shared=status['shared']

user_id = status['user'].keys.first
structure_id = status['user'][user_id]['structures'][0].split('.')[1]
wheres=status['where'][structure_id]['wheres']
devices=status['device']
devices.each_pair do |device,data|
  postal_code = data['postal_code']
  weather_query="#{weather_url}#{postal_code}"
  odrequest = HTTParty.get(weather_query)
  odresult = JSON.parse(odrequest.body) rescue nil
  outdoor_temp= convert_temp(odresult[postal_code]['current']['temp_c'])
  where_id = data['where_id']
  where = wheres.find {|w| w['where_id'] == where_id }['name'].gsub(' ','_')
  current_humidity = data['current_humidity']
  target_temp = convert_temp(shared[device]['target_temperature'])
  current_temp = convert_temp(shared[device]['current_temperature'])
  prefix= "nest.#{where}"
  g.push_to_graphite do |graphite|
    graphite.puts "#{prefix}.humidity #{current_humidity.to_i} #{g.time_now}"
    graphite.puts "#{prefix}.target_temp #{target_temp.to_i} #{g.time_now}"
    graphite.puts "#{prefix}.current_temp #{current_temp.to_i} #{g.time_now}"
    graphite.puts "#{prefix}.outdoot_temp #{outdoor_temp.to_i} #{g.time_now}"
  end
end
