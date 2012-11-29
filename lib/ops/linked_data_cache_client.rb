########################################################################################
#
# The MIT License (MIT)
# Copyright (c) 2012 BioSolveIT GmbH
#
# This file is part of the OPS gem, made available under the MIT license.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For further information please contact:
# BioSolveIT GmbH, An der Ziegelei 79, 53757 Sankt Augustin, Germany
# Phone: +49 2241 25 25 0 - Email: license@biosolveit.de
#
########################################################################################

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'
require 'httpclient'
require 'multi_json'
require 'awesome_print'

module OPS
  class LinkedDataCacheClient
    class Error < StandardError; end
    class BadStatusCode < LinkedDataCacheClient::Error; end
    class InvalidResponse < LinkedDataCacheClient::Error; end

    NON_PROPERTY_KEYS = %w(_about exactMatch inDataset isPrimaryTopicOf activity).freeze

    def initialize(url, options={})
      @url = url
      @url = @url[0..-2] if @url.end_with?('/')
      @http_client = HTTPClient.new
      @http_client.receive_timeout = options.fetch(:receive_timeout, 60)
    end

    def compound_info(compound_uri)
      return nil if not compound_uri or compound_uri.blank?
      response = execute_request("#{@url}/compound.json", :uri => compound_uri)
      check_response(response)
      json = decode_response(response)

      result = parse_items_json(json)

      OPS.log(self, :debug, "Result: #{result.inspect}")

      result
    end

    def compound_pharmacology(compound_uri)
      return nil if not compound_uri or compound_uri.blank?
      response = execute_request("#{@url}/compound/pharmacology.json", :uri => compound_uri)
      check_response(response)
      json = decode_response(response)

      result = parse_items_json(json)

      OPS.log(self, :debug, "Result: #{result.inspect}")

      result
    end

    def compound_targets(compound_uri)
      primary_results = compound_pharmacology(compound_uri)
      return nil unless primary_results
      targets = Array.new
      primary_results.each do |uri, primary_hash|
        next unless primary_hash.has_key?(:activity)
        primary_hash[:activity].each do |activity_entry|
          next unless activity_entry.has_key?(:on_assay) and activity_entry[:on_assay].has_key?(:targets) and activity_entry[:on_assay][:targets].any?
          targets +=  activity_entry[:on_assay][:targets]
        end
      end

      targets.uniq!

      OPS.log(self, :debug, "Result: #{targets.inspect}")

      targets
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

    def check_response(response)
      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200
    end

    def decode_response(response)
      MultiJson.load(response.body)
    rescue MultiJson::DecodeError
      raise InvalidResponse.new("Could not parse response")
    end

    def parse_items_json(json)
      primary_topic = json['result']['primaryTopic']

      return nil unless primary_topic.has_key?('inDataset')

      result = {
        primary_topic['inDataset'].to_sym => parse_item(primary_topic)
      }

      primary_topic['exactMatch'].each do |item|
        result[item['inDataset'].to_sym] = parse_item(item) if item.is_a?(Hash)
      end

      result
    end

    def parse_item(item)
      result = {
        :uri => item['_about'],
        :properties => parse_item_properties(item)
      }

      if item.has_key?('activity')
        result[:activity] = []
        if item['activity'].is_a?(Array)
          item['activity'].each{|a| result[:activity] << parse_activity(a) if a.has_key?('inDataset')}
        else
          result[:activity] << parse_activity(item['activity']) if item['activity'].has_key?('inDataset')
        end
      end

      result
    end

    def parse_item_properties(item)
      properties = {}

      item.each do |key, value|
        properties[key.underscore.to_sym] = value unless NON_PROPERTY_KEYS.include?(key)
      end

      properties
    end

    def parse_activity(activity)
      on_assay = activity['onAssay']
      targets = if on_assay['target'].nil?
        []
      elsif on_assay['target'].is_a?(Hash)
        [parse_assey_target(on_assay['target'])]
      elsif on_assay['target'].is_a?(String)
        [{
          :uri => on_assay['target'],
          :title => ""
        }]
      else
        on_assay['target'].collect do |target|
          parse_assey_target(target)
        end
      end

      {
        :uri => activity['_about'],
        :on_assay => {
          :uri => on_assay['_about'],
          :assay_organism => on_assay['assay_organism'],
          :targets => targets
        },
        :relation => activity['relation'],
        :standard_units => activity['standardUnits'],
        :standard_value => activity['standardValue'],
        :activity_type => activity['activity_type'],
      }
    end

    def parse_assey_target(target)
      {
        :uri => target['_about'],
        :title => target['title']
      }
    end
  end
end