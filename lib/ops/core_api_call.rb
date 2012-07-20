require 'ops/coreapi_response_parser'
require 'net/http'
require 'uri'

module OPS
  class CoreApiCall
    attr :success
    attr :http_error

    def initialize(url, open_timeout = 60, read_timeout = 300)
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

      request_core_api(api_method, options)
    end

  private
    def request_core_api(api_method, options)
      options[:method] = api_method
      options[:limit] ||= 100
      options[:offset] ||= 0

      OPS.log(self, :info, "Issues call to coreAPI on #{@uri} with options: #{options.inspect}")

      response = nil
      start_time = Time.now

      request = Net::HTTP::Post.new(@uri.path)
      # Tweak headers, removing this will default to application/x-www-form-urlencoded
      request["Content-Type"] = "application/json"
      request.form_data = options

      begin
        @http.start do |http|
          response = http.request(request)
        end
      rescue Timeout::Error
        query_time = Time.now - start_time
        OPS.log(self, :error, "Timeout after #{query_time} seconds")
        raise
      end

      response_time = Time.now
      query_time = Time.now - start_time
      OPS.log(self, :debug, "Call took #{query_time} seconds")

      status = response.code.to_i
      status = case response.code.to_i
        when 100..199 then
          @http_error = "HTTP #{status.to_s}-error"
          OPS.log(self, :error, @http_error)
          return nil
        when 200 then #HTTPOK =>  Success
          @success = true
          parsed_responce = OPS::CoreApiResponseParser.parse_response(response)

          result = parsed_responce.collect do |solution|
            rdf = solution.to_hash
            rdf.each { |key, value| rdf[key] = value.to_s }
            rdf
          end

          OPS.log(self, :info, "Result: #{result.nil? ? 0 : result.length} items")
          OPS.log(self, :debug, "Result: #{result.inspect}")

          return result
        when 201..407 then
          @http_error = "HTTP #{status.to_s}-error"
          OPS.log(self, :error, @http_error)
          return nil
        when 408 then
          @http_error = "HTTP post to core API timed out"
          OPS.log(self, :error, @http_error)
          return nil
        when 409..600 then
          @http_error = "HTTP #{status.to_s}-error"
          OPS.log(self, :error, @http_error)
          return nil
      end
    end
  end
end
