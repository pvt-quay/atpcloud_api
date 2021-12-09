#!/usr/bin/ruby

load './lib/http/errors.rb'
require "rest_client"
require "net/http"
require "uri"

class ATP
	def initialize(options = {token: nil, base_uri: nil, debug: false})
		@options = options
		check_opts
	end

	def get(uri)
		exec(uri, 'get')
	end

	def get_ih(uri)
		exec(uri, 'get')
	end

	def hash(uri)
		exec(uri, 'get')
	end

	def ping(uri)
		exec(uri, 'get')
	end

	def delete(uri)
		exec(uri, 'delete')
	end

	def patch(uri)
		exec(uri, 'patch')
	end

	def post(uri)
		exec(uri, 'post')
	end

	private

	def exec(uri, method = 'get')
		http, uri = init_http(@options[:base_uri] + uri)
		case method
		when 'get'
			request = Net::HTTP::Get.new(uri.request_uri)
		when 'patch'
			@form_data = compose_form_data
			request = Net::HTTP::Patch.new(uri.request_uri)
		when 'delete'
			@form_data = compose_form_data
			request = Net::HTTP::Delete.new(uri.request_uri)
		when 'post'
			@form_data = compose_form_data
			request = Net::HTTP::Post.new(uri.request_uri)
			request.set_form_data @form_data
		end
		do_request(http, request)
	end

	#def do_request(http, request, form_data = nil)
	def do_request(http, request)
		puts "FORM DATA ATP::do_request(): #{@form_data}" if @options[:debug]
		request["Authorization"] = 'Bearer ' + @options[:token] unless @options[:token] == false
		begin
			case @form_data
			when nil
				resp = http.request(request)
			else
				request.set_form(@form_data, 'multipart/form-data')
				resp = http.request(request)
			end
		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, SocketError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED => e
			puts e
			exit 1
		end
		if resp.code == '200' || resp.code == '202'
			puts "#{resp.code} received: #{APIErrors::ERRORS[:"#{resp.code}"]}" if @options[:debug]
		else
			puts "#{resp.code} received: #{APIErrors::ERRORS[:"#{resp.code}"]}"
			exit 1
		end
		return resp
	end

	def init_http(uri)
		uri = URI.parse(uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @options[:no_ssl_verify]
		http.set_debug_output $stderr if @options[:debug]
		return http, uri
	end

	def compose_form_data
		if @options[:one_or_n] == 'file' && @options[:action] != 'submit' then
  		[[ 'file', File.read(@options[:filename]), filename: @options[:filename] ]]
		elsif @options[:one_or_n] == 'param' then
  		[[ 'server', @options[@options[:server_type].intern], server: @options[@options[:server_type].intern] ]]
		elsif @options[:one_or_n] == 'file' && @options[:action] == 'submit'
  		#[[ 'file', File.read(@options[:filename]), filename: @options[:filename], sample_url: 'https://totallymadeup.com', remote_ip: '127.0.0.1' ]]
  		[[ 'file', File.read(@options[:filename]), filename: @options[:filename] ]]
		else
			nil
		end
	end

	def check_opts
		# this script uses blocklist/allowlist but the API uses blacklist/whitelist
		if @options[:api_ver] == 'v2' && @options[:list] != nil
			@options[:list].sub!("blocklist", "blacklist")
   		@options[:list].sub!("allowlist", "whitelist")
		end

		if @options[:base_uri] == nil && ! @options[:version] == true
			raise 'options[:base_uri] is required'
			exit 1
		end

		if @options[:token] == nil
			raise 'options[:token] is required'
			exit 1
		end
	end
end
