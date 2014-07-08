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
require 'ops/ldc'

module OPS
  class OpenPhactsClient

    def initialize(config, options={})
      [:url, :app_id, :app_key].each do |key|
        raise MissingArgument, key if config[key].nil? or config[key].empty?
      end
      raise InvalidArgument, :url if (config[:url] =~ /^http[s]{0,1}:\/\//) == nil
      @url = config[:url]
      @url = @url[0..-2] if @url.end_with?('/')
      @default_params = {:_format => 'json', :app_id => config[:app_id], :app_key => config[:app_key]}.freeze
      @http_client = HTTPClient.new
      @http_client.receive_timeout = options.fetch(:receive_timeout, 60)
    end

    def compound_info(compound_uri, options={})
      return nil if not compound_uri or compound_uri.blank?
      query_api('compound', options.merge(:uri => compound_uri), Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def compound_info_batch(compound_uris, options={})
      return nil if not compound_uris or compound_uris.empty?
      compound_uris = compound_uris.join("|") if compound_uris.is_a?(Array)
      query_api('compound/batch', options.merge(:uri_list => compound_uris), Proc.new{|data| OPS::LDC.parse_batch_json(data)})
    end

    def compound_pharmacology(compound_uri, options={})
      return nil if not compound_uri or compound_uri.blank?
      options[:_pageSize] = 'all' unless options.has_key?(:_pageSize)
      query_api('compound/pharmacology/pages', options.merge(:uri => compound_uri), Proc.new{|data| OPS::LDC.parse_paginated_json(data)})
    end

    def compound_pharmacology_count(compound_uri, options={})
      return nil if not compound_uri or compound_uri.blank?
      query_api('compound/pharmacology/count', options.merge(:uri => compound_uri), Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def target_pharmacology(target_uri, options={})
      return nil if not target_uri or target_uri.blank?
      options[:_pageSize] = 'all' unless options.has_key?(:_pageSize)
      query_api('target/pharmacology/pages', options.merge(:uri => target_uri), Proc.new{|data| OPS::LDC.parse_paginated_json(data)})
    end

    def target_pharmacology_count(target_uri, options={})
      return nil if not target_uri or target_uri.blank?
      query_api('target/pharmacology/count', options.merge(:uri => target_uri), Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def target_info(target_uri, options={})
      return nil if not target_uri or target_uri.blank?
      query_api('target', options.merge(:uri => target_uri), Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def target_info_batch(target_uris, options={})
      return nil if not target_uris or target_uris.empty?
      target_uris = target_uris.join("|") if target_uris.is_a?(Array)
      query_api('target/batch', options.merge(:uri_list => target_uris), Proc.new{|data| OPS::LDC.parse_batch_json(data)})
    end

    def smiles_to_url(smiles, options={})
      return nil if not smiles or smiles.blank?
      query_api('structure', options.merge(:smiles => smiles), Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def similarity_search(smiles, options={})
      return nil if not smiles or smiles.blank?
      opts = options.merge('searchOptions.Molecule' => smiles)
      query_api('structure/similarity', opts, Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

    def substructure_search(smiles, options={})
      return nil if not smiles or smiles.blank?
      opts = options.merge('searchOptions.Molecule' => smiles, 'searchOptions.MolType' => 0)
      query_api('structure/substructure', opts, Proc.new{|data| OPS::LDC.parse_primary_topic_json(data)})
    end

  private

    def query_api(request_path, params, json_parser=nil)
      params.merge!(@default_params)
      response = execute_request("#{@url}/#{request_path}", params)
      check_resonse(response)
      json = decode_response(response)
      result = json_parser.nil? ? json : json_parser.call(json)

      OPS.log(self, :debug, "Result (#{request_path}): #{result.inspect}")
      result = nil if result.size == 1 and result.is_a?(Hash) and result.keys == [:uri]
      result
    end

    def execute_request(url, options)
      OPS.log(self, :info, "Issues call to Linked Data Cache API URL '#{url}' with options: #{options.inspect}")
      start_time = Time.now
      response = nil

      begin
        response = if (url.end_with?('/batch'))
          @http_client.post(url, options)
        else
          @http_client.get(url, options)
        end
      rescue Timeout::Error
        query_time = Time.now - start_time
        OPS.log(self, :error, "Timeout after #{query_time} seconds")
        raise
      end

      query_time = Time.now - start_time
      OPS.log(self, :debug, "Call took #{query_time} seconds")
      response
    end

    def check_resonse(response)
      unless response.code == 200
        e = case response.code
          when 403 then OPS::ForbiddenError
          when 400 then OPS::BadRequestError
          when 404 then OPS::NotFoundError
          when 414 then OPS::UriTooLarge
          when 500 then OPS::InternalServerError
          when 504 then OPS::GatewayTimeoutError
          else OPS::ServerResponseError
        end
        OPS.log(self, :error, "#{e}: #{response.inspect}")
        raise e
      end
    end

    def decode_response(response)
      MultiJson.load(response.body)
    rescue MultiJson::DecodeError
      raise InvalidJsonResponse, "Could not parse response"
    end

  end
end
