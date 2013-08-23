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

require 'httpclient'
require 'nokogiri'

module OPS
  class JsonChemspiderClient
    class Error < StandardError; end
    class BadStatusCode < JsonChemspiderClient::Error; end
    class Failed < JsonChemspiderClient::Error; end
    class InvalidResponse < JsonChemspiderClient::Error; end
    class FrameworkError < JsonChemspiderClient::Error; end


    DEFAULT_RESULT_LIMIT = 100
    DEFAULT_RESULT_TYPE = :ids
    DEFAULT_SIMILARITY_SEARCH_THRESHOLD = 0.99
    RESULTS_OPERATIONS = {
      :ids => 'GetSearchResult',
      :compounds => 'GetSearchResultAsCompounds',
    }

    DEFAULT_SEARCH_PARAMS = {
      'scopeOptions.DataSources[0]' => 'DrugBank',
      'scopeOptions.DataSources[1]' => 'ChEMBL',
      'scopeOptions.DataSources[2]' => 'ChEBI',
      'scopeOptions.DataSources[3]' => 'PDB',
      'scopeOptions.DataSources[4]' => 'MeSH',
    }

    def initialize(url, search_default_limit=DEFAULT_RESULT_LIMIT, search_status_wait_duration=0.5)
      @url = url
      DEFAULT_SEARCH_PARAMS['resultOptions.Limit'] = search_default_limit
      @search_status_wait_duration = search_status_wait_duration
      @http_client = HTTPClient.new
    end

    def exact_structure_search(smiles, options={})
      params = DEFAULT_SEARCH_PARAMS.merge({
        'op' => 'ExactStructureSearch',
        'searchOptions.Molecule' => smiles
      })

      make_smiles_based_search(params, 'ExactStructureSearch', smiles, options.fetch(:result_type, DEFAULT_RESULT_TYPE))
    end

    def similarity_search(smiles, options={})
      params = DEFAULT_SEARCH_PARAMS.merge({
        'op' => 'SimilaritySearch',
        'searchOptions.Molecule' => smiles,
        'searchOptions.Threshold' => options.fetch(:threshold, DEFAULT_SIMILARITY_SEARCH_THRESHOLD).to_f,
      })

      params.apply_common_search_options!(options)

      if options.has_key?(:similarity_type) and %w(Tanimoto Tversky Euclidian).include?(options[:similarity_type].to_s.camelize)
        params['searchOptions.SimilarityType'] = options[:similarity_type].to_s.camelize
      else
        params['searchOptions.SimilarityType'] = 'Tanimoto'
      end

      make_smiles_based_search(params, 'SimilaritySearch', smiles, options.fetch(:result_type, DEFAULT_RESULT_TYPE))
    end

    def substructure_search(smiles, options={})
      params = DEFAULT_SEARCH_PARAMS.merge({
        'op' => 'SubstructureSearch',
        'searchOptions.Molecule' => smiles
      })

      params.apply_common_search_options!(options)

      if options.has_key?(:match_tautomers) and %w(true false).include?(options[:match_tautomers].to_s)
        params['searchOptions.MatchTautomers'] = options[:match_tautomers].to_s
      else
        params['searchOptions.MatchTautomers'] = 'false'
      end

      make_smiles_based_search(params, 'SubstructureSearch', smiles, options.fetch(:result_type, DEFAULT_RESULT_TYPE))
    end

  private
    def make_smiles_based_search(params, type, smiles, result_type)
      OPS.log(self, :info, "Issues call to ChemSpider for '#{type}' with smiles '#{smiles}'")
      OPS.log(self, :debug, "\nparams: #{params.inspect}\n")
      start_time = Time.now

      response = @http_client.get(@url, params, { 'Content-Type' => 'application/json; charset=utf-8' })
      OPS.log(self, :debug, "\n#{response.inspect}\n")

      if response.code != 200
        OPS.log(self, :error, "smiles based search returned response code #{response.code} (#{smiles}): #{response.body}")
        raise BadStatusCode.new("Smiles based search responded with status code #{response.code}")
      end

      transaction_id = response.body

      result = wait_for_search_result(transaction_id, result_type)
      query_time = Time.now - start_time

      OPS.log(self, :debug, "(#{transaction_id}) Call took #{query_time} seconds")

      result
    end

    def get_async_search_status(transaction_id)
      response = @http_client.get(@url, { 'op' => 'GetSearchStatus', 'rid' => transaction_id },
                                  { 'Content-Type' => 'application/json; charset=utf-8' })

      if response.code != 200
        OPS.log(self, :error, "search status returned response code #{response.code} (#{transaction_id}): #{response.body}")
        raise BadStatusCode.new("Search status responded with status code #{response.code}")
      end

      begin
        MultiJson.load(response.body)
      rescue MultiJson::DecodeError
        OPS.log(self, :error, "search status decode error (#{transaction_id}): #{response.body}")
        raise InvalidResponse.new("Could not parse response")
      end
    end

    def get_async_search_result(transaction_id, result_type)
      response = @http_client.get(@url, { 'op' => RESULTS_OPERATIONS[result_type], 'rid' => transaction_id },
                                  { 'Content-Type' => 'application/json; charset=utf-8' })

      if response.code != 200
        OPS.log(self, :error, "search result returned response code #{response.code} (#{transaction_id}): #{response.body}")
        raise BadStatusCode.new("Search result responded with status code #{response.code}")
      end

      begin
        MultiJson.load(response.body)
      rescue MultiJson::DecodeError
        OPS.log(self, :error, "search result decode error (#{transaction_id}): #{response.body}")
        raise InvalidResponse.new("Could not parse response")
      end
    end

    def wait_for_search_result(transaction_id, result_type)
      OPS.log(self, :debug, "(#{transaction_id}) Wait for search result for transaction")

      search_status = nil
      while search_status != "Finished" do
        sleep(@search_status_wait_duration) unless search_status.nil?
        search_status = get_async_search_status(transaction_id)['Message']
        OPS.log(self, :debug, "(#{transaction_id}) Search status: '#{search_status}'")
        next if search_status.nil?

        if search_status == "Failed"
          OPS.log(self, :error, "error during wait for search result (#{transaction_id}): #{search_status}")
          raise Failed.new("ChemSpider returned request status 'Failed'")
        elsif search_status == "TooManyRecords"
          OPS.log(self, :error, "error during wait for search result (#{transaction_id}): #{search_status}")
          raise TooManyRecords.new("ChemSpider returned request status 'TooManyRecords'")
        elsif search_status.start_with?("A .NET Framework error occurred")
          OPS.log(self, :error, "error during wait for search result (#{transaction_id}): #{search_status}")
          raise FrameworkError.new("ChemSpider returned request status 'FrameworkError'")
        end
      end

      result = get_async_search_result(transaction_id, result_type)

      OPS.log(self, :info, "(#{transaction_id}) Search result: #{result}")

      result
    end
  end
end

class Hash
  def apply_common_search_options!(options_hash)
    self.apply_generic_search_options!(options_hash)

    if options_hash.has_key?(:complexity) and %w(Any Single Multi).include?(options_hash[:complexity].to_s.camelize)
      self['commonOptions.Complexity'] = options_hash[:complexity].to_s.camelize
    end

    if options_hash.has_key?(:isotopic) and %w(Any Labeled NotLabeled).include?(options_hash[:isotopic].to_s.camelize)
      self['commonOptions.Isotopic']   = options_hash[:isotopic].to_s.camelize
    end

    if options_hash.has_key?(:has_spectra) and %w(true false).include?(options_hash[:has_spectra].to_s)
      self['commonOptions.HasSpectra'] = options_hash[:has_spectra].to_s
    end

    if options_hash.has_key?(:has_patents) and %w(true false).include?(options_hash[:has_patents].to_s)
      self['commonOptions.HasPatents'] = options_hash[:has_patents].to_s
    end
  end

  def apply_generic_search_options!(options_hash)
    if options_hash.has_key?(:limit)
      self['resultOptions.Limit'] = options_hash[:limit].to_i
    end
  end
end
