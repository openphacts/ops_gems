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

    NON_PROPERTY_KEYS = %w(_about inDataset isPrimaryTopicOf).freeze

    def initialize(url, options={})
      @url = url
      @url = @url[0..-2] if @url.end_with?('/')
      @http_client = HTTPClient.new
      @http_client.receive_timeout = options.fetch(:receive_timeout, 60)
    end

    def compound_info(compound_uri)
      return nil if not compound_uri or compound_uri.blank?
      query_api(:compound_info, compound_uri)
    end

    def compound_pharmacology(compound_uri)
      return nil if not compound_uri or compound_uri.blank?
      query_api(:compound_pharmacology, compound_uri)
    end

    def compound_pharmacology_count(compound_uri)
      return nil if not compound_uri or compound_uri.blank?
      query_api(:compound_pharmacology_count, compound_uri)
    end

    def target_pharmacology(target_uri)
      return nil if not target_uri or target_uri.blank?
      query_api(:target_pharmacology, target_uri)
    end

    def target_pharmacology_count(target_uri)
      return nil if not target_uri or target_uri.blank?
      query_api(:target_pharmacology_count, target_uri)
    end

    def target_info(target_uri)
      return nil if not target_uri or target_uri.blank?
      query_api(:target_info, target_uri)
    end

  private

    def query_api(method, uri)
      return nil if not uri or uri.blank?

      request_path = case method
        when :compound_info then 'compound.json'
        when :compound_pharmacology then 'compound/pharmacology.json'
        when :compound_pharmacology_count then 'compound/pharmacology/count.json'
        when :target_info then 'target.json'
        when :target_pharmacology then 'target/pharmacology.json'
        when :target_pharmacology_count then 'target/pharmacology/count.json'
      end

      response = execute_request("#{@url}/#{request_path}", :uri => uri)
      check_response(response)
      json = decode_response(response)
      result = parse_items_json(json)

      OPS.log(self, :debug, "Result (#{method}): #{result.inspect}")
      result
    end

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
      # process count request results
      if primary_topic.has_key?('targetPharmacologyTotalResults')
        return {:uri => primary_topic['_about'], :count => primary_topic['targetPharmacologyTotalResults']}
      elsif primary_topic.has_key?('compoundPharmacologyTotalResults')
        return {:uri => primary_topic['_about'], :count => primary_topic['compoundPharmacologyTotalResults']}
      end
      # process all other results
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
      properties = {:uri => item['_about']}
      item.each do |key, value|
        next if NON_PROPERTY_KEYS.include?(key)
        if value.is_a?(Hash) and value.has_key?('_about')
          properties[key.underscore.to_sym] = parse_item(value)
        elsif value.is_a?(Array)
          properties[key.underscore.to_sym] = value.collect{|e| e.is_a?(Hash) ? parse_item(e) : e}
        else
          properties[key.underscore.to_sym] = value
        end
      end
      properties
    end

  end
end