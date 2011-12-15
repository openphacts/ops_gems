require 'ops/coreapi_response_parser'
require 'net/http'
require 'uri'

module OPS
  class CoreApiCall
    CORE_API_URL = "http://ops.few.vu.nl:9183/opsapi"

    attr :success
    attr :http_error

    def initialize(url = CORE_API_URL, open_timeout = 60, read_timeout = 300)
      # Configuring the connection
      @uri = URI.parse(url)
      @success = false
      @http_error = nil

      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.open_timeout = open_timeout # in seconds
      @http.read_timeout = read_timeout # in seconds
    end

    def request(api_method, options)
      raise "No method API method selected! Please specify a OPS coreAPI method" if api_method.nil?

      options[:method] = api_method
      options[:limit] ||= 100
      options[:offset] ||= 0

      puts "\nIssues call to coreAPI on #{@uri} with options: #{options.inspect}\n"

      response = nil
      start_time = Time.now

      @http.start do |http|
        request = Net::HTTP::Post.new(@uri.path)
        # Tweak headers, removing this will default to application/x-www-form-urlencoded
        request["Content-Type"] = "application/json"
        request.form_data = options

        response = http.request(request)
      end

      response_time = Time.now
      query_time = Time.now - start_time
      puts "Call took #{query_time} seconds"

      status = case response.code.to_i
        when 100..199 then
          @http_error = "HTTP {status.to_s}-error"
          puts @http_error
          return nil
        when 200 then #HTTPOK =>  Success
          @success = true
          parsed_responce = OPS::CoreApiResponseParser.parse_response(response)
          puts parsed_responce.inspect
          return parsed_responce.collect do |solution|
            rdf = solution.to_hash
            rdf.each { |key, value| rdf[key] = value.to_s }
            rdf
          end
        when 201..407 then
          @http_error = "HTTP {status.to_s}-error"
          puts @http_error
          return nil
        when 408 then
          @http_error = "HTTP post to core API timed out"
          puts @http_error
          return nil
        when 409..600 then
          @http_error = "HTTP {status.to_s}-error"
          puts @http_error
          return nil
      end
    end
  end
end
