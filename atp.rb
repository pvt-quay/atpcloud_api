#!/usr/bin/ruby

load './lib/version.rb'
load './lib/opts/opts.rb'
load './lib/http/http.rb'

form_data = ''
list = $options[:list]
server_type = $options[:server_type]
one_or_n = $options[:one_or_n]

atp = ATP.new($options)

case $options[:action]
when 'get'
	response = atp.get("/#{list}/#{one_or_n}/#{server_type}")
when 'ih'
	response = atp.get_ih('/infected_hosts')
when 'add'
	response = atp.patch("/#{list}/#{one_or_n}/#{server_type}")
when 'delete'
	response = atp.delete("/#{list}/#{one_or_n}/#{server_type}")
when 'lookup'
	response = atp.hash("/lookup/hash/#{$options[:hash]}")
when 'ping'
	response = atp.ping("/ping")
when 'version'
	puts "#{Version::VERSION}"
	exit
end
puts response.body
