require 'optparse'
require 'ipaddr'

def check_action(options)
	if options.key? :action
		puts "Only one action is allowed and \"#{options[:action]}\" is already specified"
		exit 1
	end
end

def check_server_type(options)
	if options.key? :server_type 
		puts "Only one server type allowed and \"#{options[:server_type]}\" is already specified"
		exit 1
	end
end

def check_list(options)
	if options.key? :list 
		puts "Only one list type allowed and \"#{options[:list]}\" is already specified"
		exit 1
	end
end

ARGV << '-h' if ARGV.empty?

# one_or_n; 'param' is one (default), 'file' is n (more than one)
options = {debug: false, one_or_n: 'param', api_ver: 'v2'}
options[:base_uri] = "https://api.sky.junipersecurity.net/#{options[:api_ver]}/skyatp"
opt_parser = OptionParser.new do |opts|

	opts.banner = "Description: Interfaces to ATP Cloud API\nUsage: #{$0} [options]"
		
 	opts.on("-a", "--action ACTION", "Action to perform - ping, get, add, delete, lookup, submit") do |a|
		check_action options
		if ! ["ping","get","add","delete","lookup","submit"].include?(a) then 
			puts 'Action must be one of "ping", "get", "add", "delete", "lookup" or "submit"'
			exit 1 
		end
 		options[:action] = a
		options[:token] = false if options[:action] == 'ping'
 		options[:one_or_n] = false if options[:action] == 'ping'
 	end

 	opts.on("-d", "--debug", "Turn on debug output - goes to STDERR") do |d|
 		options[:debug] = true
 	end

	opts.on("-D", "--domain [DOMAIN|FILE]", String, "Domain or file with domains - used with get, add or delete actions") do |d|
		check_server_type options
		if d == nil
			# no parameter means we're just getting the contents of the list for the domain entity type
			options[:server_type] = 'domain'
		else
			# user has specified a domain directly on CLI or a filename with domain names
			begin
				# open file just to test if we're being passed a filename
				f = File.open(d)
 				options[:filename] = d
 				options[:one_or_n] = 'file'
			rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
				if d.is_a?(String) then
 					options[:domain] = d
				else
					puts '"domain" requires a domain or a readable file as an argument'
					exit 1
				end
			end	
			options[:server_type] = 'domain'
		end
 	end

	opts.on("-i", "--ip [IP|FILE]", String, "IP address or file with IPs - used with get, add or delete actions") do |i|
		check_server_type options
		if i == nil
			options[:server_type] = 'ip'
		else
			begin
				# test if argument is an ip address
				IPAddr.new(i) if i != nil
 				options[:ip] = i
			rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
				# not an IP address, test if readable file
				begin	
					File.open(i)
 					options[:filename] = i
 					options[:one_or_n] = 'file'
				rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
					puts '"ip" requires an IP address or a readable file as an argument'
					exit 1
				end
			end
			options[:server_type] = 'ip'
		end
	end

 	opts.on("-I", "--ih", 'Get the Infected Hosts feed') do |ih|
		check_action options
 		options[:action] = 'ih'
 	end

  opts.on("-H", "--hash HASH|FILE", String, "A SHA256 file hash - used with lookup action") do |hash|
		check_action options
    begin
      options[:hash] = File.read(hash).chomp
    rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
      if hash.is_a?(String) then
        options[:hash] = hash
      else
        puts 'argument to "-H" is neither a string nor a file'
        exit 1
      end
    end
    options[:action] = 'lookup'
    options[:one_or_n] = false
  end
	
 	opts.on("-k", "--no_ssl_verify", "Turn off ssl certificate verification - INSECURE!") do |k|
 		options[:no_ssl_verify] = true
 	end

	opts.on("-l", "--list LIST", 'List to utilize - must be allowlist or blocklist, used with get,', 'add or delete actions') do |l|
		check_list options
		if ! ["allowlist","blocklist"].include?(l) then 
			puts 'List must be one of "allowlist" or "blocklist"'
			exit 1
		end
 		options[:list] = l
 	end

 	opts.on("-p", "--ping", 'Ping the API - If alive, the API should return "I am a potato."', 'Alias for "-a ping"') do |ih|
		check_action options
 		options[:action] = 'ping'
 		options[:token] = false
 		options[:one_or_n] = false
 	end

	opts.on("-s", "--submit FILE", String, "Submit a malware sample for analysis") do |s|
		check_action options
		begin	
			File.open(s)
			options[:filename] = s
			options[:action] = 'submit'
			options[:one_or_n] = 'file'
		rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
			puts '"submit" action requires a readable file as an argument'
			exit 1
		end
	end
	
 	opts.on("-t", "--token STRING|FILE", "Authorization token") do |t|
		begin	
			options[:token] = File.read(t).chomp
		rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
			if t.is_a?(String) then
				if t !~ /\A[\w\-\.]+\z/
					puts "Invalid token specified"
					exit 1
				end
 				options[:token] = t
			else
				'"token" argument requires a string or a file'
				exit 1
			end
		end
 	end

	opts.on("-u", "--url [URL|FILE]", String, "URL or file with URLs - used with get, add or delete actions") do |u|
		check_server_type options
		if u != nil
			begin
				File.open(u)
 				options[:filename] = u
 				options[:one_or_n] = 'file'
			rescue Errno::EACCES, Errno::ENOENT, Errno::ENAMETOOLONG
 				options[:url] = u
			end
 		end
		options[:server_type] = 'url'
	end

 	opts.on("-v", "--version", 'Shows the version') do |v|
		options = options.clear
		options[:version] = true
		options[:action] = 'version'
		options[:token] = false
 	end

 	opts.on("-h", "-?", "--help", "Prints this help") do
 		puts opts
 		exit
 	end
end

begin
	opt_parser.parse!(into: {})
rescue OptionParser::MissingArgument => e
	puts "Specified parameter #{e.args} requires an argument"
	exit 1
rescue OptionParser::InvalidArgument => e
	puts "Specified parameter #{e.args} invalid argument"
	exit 1
end

if ! options.key?(:token)
	puts 'no authorization token specified'
	exit 1
end

case options[:action]
when 'ping'
when 'submit'
when 'ih'
when 'lookup'
	if options[:hash] == nil
		puts "Action \"#{options[:action]}\" requires a hash (-H or --hash)"
	end
when 'get', 'delete', 'add'
	if options[:server_type] == nil
		puts "Action \"#{options[:action]}\" requires a server type (domain, url or ip)"
	elsif options[:list] == nil
		puts "Action \"#{options[:action]}\" requires a list type (blocklist or allowlist)"
	end
end

$options = options
pp $options if $options[:debug]
