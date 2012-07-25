require 'httpclient'
require 'nokogiri'

module OPS
  class LinkedDataCacheClient
    class Error < StandardError; end
    class BadStatusCode < LinkedDataCacheClient::Error; end

    def initialize(url)
      @url = url
      @url = @url[0..-2] if @url.end_with?('/')
      @http_client = HTTPClient.new
    end

    def compound_info(compound_uri)
      response = execute_request("#{@url}/compound.xml", :uri => compound_uri)

      parse_response(response)
    end

  private
    def execute_request(url, options)
      OPS.log(self, :info, "Issues call to Linked Data Cache API URL '#{url}' with options: #{options.inspect}")

      start_time = Time.now
      response = nil

      begin
        response = @http_client.get(url, options)
      rescue Timeout::Error
        query_time = Time.now - start_time
        OPS.log(self, :error, "Timeout after #{query_time} seconds")
        raise
      end

      query_time = Time.now - start_time
      OPS.log(self, :debug, "Call took #{query_time} seconds")

      response
    end

    def parse_response(response)
      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      result = nil
      document = Nokogiri::XML(response.body)
      primary_topics = document.xpath('//result/primaryTopic[1]')

      unless primary_topics.children.empty?
        primary_topic = primary_topics.first

        result = {
          primary_topic.xpath('./inDataset').first['href'] => {
            :href => primary_topic['href'],
            :properties => parse_property_nodes(primary_topic.xpath('./*[not(self::exactMatch) and not(self::inDataset)]'))
          }
        }

        primary_topic.xpath("./exactMatch/item[@href != '#{primary_topic['href']}']").each do |item|
          result[item.xpath('./inDataset').first['href']] = {
            :href => item['href'],
            :properties => parse_property_nodes(item.xpath('./*[not(self::exactMatch) and not(self::inDataset)]'))
          }
        end
      end

      OPS.log(self, :info, "Result: #{result.nil? ? 0 : result.length} items")
      OPS.log(self, :debug, "Result: #{result.inspect}")

      result
    end

    def parse_property_nodes(property_nodes)
      properties = {}

      property_nodes.each do |property_node|
        properties[property_node.name.to_sym] = property_node.content
      end

      properties
    end
  end
end