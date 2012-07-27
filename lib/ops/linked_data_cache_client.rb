require 'active_support/core_ext/string/inflections'
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

    def compound_pharmacology_info(compound_uri)
      response = execute_request("#{@url}/compound/pharmacology.xml", :uri => compound_uri)

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
          primary_topic.xpath('./inDataset').first['href'] => parse_item_node(primary_topic)
        }

        primary_topic.xpath("./exactMatch/item[@href != '#{primary_topic['href']}']").each do |item|
          result[item.xpath('./inDataset').first['href']] = parse_item_node(item)
        end
      end

      OPS.log(self, :info, "Result: #{result.nil? ? 0 : result.length} items")
      OPS.log(self, :debug, "Result: #{result.inspect}")

      result
    end

    def parse_item_node(item_node)
      result = {
        :uri => item_node['href'],
        :properties => parse_property_nodes(item_node.xpath('./*[not(self::exactMatch) and not(self::inDataset) and not(*)]'))
      }

      activity = item_node.xpath('./activity')

      unless activity.children.empty?
        activity = activity.first

        result[:activity] = []

        activity.children.each do |a|
          result[:activity] << parse_activity_node(a) unless a.xpath('./*[not(self::forMolecule)]').children.empty?
        end
      end

      result
    end

    def parse_activity_node(activity_node)
      on_assay_node = activity_node.xpath('./onAssay').first

      result = {
        :uri => activity_node['href'],
        :on_assay => {
          :uri => on_assay_node['href'],
          :organism => on_assay_node.xpath('./assay_organism').first.content,
          :targets => []
        },
        :relation => activity_node.xpath('./relation').first.content,
        :standard_units => activity_node.xpath('./standardUnits').first.content,
        :standard_value => activity_node.xpath('./standardValue').first.content.to_f,
        :type => activity_node.xpath('./activity_type').first.content,
      }

      target_node = on_assay_node.xpath('./target').first

      if target_node.has_attribute?('href')
        result[:on_assay][:targets] << parse_assey_target_node(target_node)
      else
        target_node.children.each do |target_node|
          result[:on_assay][:targets] << parse_assey_target_node(target_node)
        end
      end

      result
    end

    def parse_assey_target_node(target_node)
      {
        :uri => target_node['href'],
        :title => target_node.xpath('./title').first.content
      }
    end

    def parse_property_nodes(property_nodes)
      properties = {}

      property_nodes.each do |property_node|
        properties[property_node.name.underscore.to_sym] = parse_property_value(property_node.content)
      end

      properties
    end

    def parse_property_value(value)
      begin
        Integer(value)
      rescue ArgumentError, TypeError
        begin
          Float(value)
        rescue ArgumentError, TypeError
          value
        end
      end
    end
  end
end