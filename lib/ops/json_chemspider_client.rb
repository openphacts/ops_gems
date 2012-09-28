require 'httpclient'
require 'nokogiri'

module OPS
  class JsonChemspiderClient
    class Error < StandardError; end
    class BadStatusCode < JsonChemspiderClient::Error; end
    class Failed < JsonChemspiderClient::Error; end
    class InvalidResponse < JsonChemspiderClient::Error; end

    URL = 'http://www.chemspider.com/JSON.ashx'
    RESULTS_OPERATIONS = {
      :ids => 'GetSearchResult',
      :compounds => 'GetSearchResultAsCompounds',
    }
    DEFAULT_RESULT_TYPE = :ids
    DEFAULT_SIMILARITY_SEARCH_THRESHOLD = 0.99

    def initialize(search_status_wait_duration=0.5)
      @search_status_wait_duration = search_status_wait_duration
      @http_client = HTTPClient.new
    end

    def exact_structure_search(smiles, options = nil)
      options ||= {}
      params = {
        'op' => 'ExactStructureSearch',
        'searchOptions.Molecule' => smiles,
        'scopeOptions.DataSources[0]' => 'DrugBank',
        'scopeOptions.DataSources[1]' => 'ChEMBL',
        'scopeOptions.DataSources[2]' => 'ChEBI',
        'scopeOptions.DataSources[3]' => 'PDB',
        'scopeOptions.DataSources[4]' => 'MeSH'
      }

      make_smiles_based_search(params, "ExactStructureSearch", smiles, options.fetch(:result_type, DEFAULT_RESULT_TYPE))
    end

    def similarity_search(smiles, options = nil)
      options ||= {}
      params = {
        'op' => 'SimilaritySearch',
        'searchOptions.Molecule' => smiles,
        'searchOptions.SimilarityType' => 'Tanimoto',
        'searchOptions.Threshold' => options.fetch(:threshold, DEFAULT_SIMILARITY_SEARCH_THRESHOLD),
        'scopeOptions.DataSources[0]' => 'DrugBank',
        'scopeOptions.DataSources[1]' => 'ChEMBL',
        'scopeOptions.DataSources[2]' => 'ChEBI',
        'scopeOptions.DataSources[3]' => 'PDB',
        'scopeOptions.DataSources[4]' => 'MeSH'
      }

      make_smiles_based_search(params, "SimilaritySearch", smiles, options.fetch(:result_type, DEFAULT_RESULT_TYPE))
    end

  private
    def make_smiles_based_search(params, type, smiles, result_type)
      OPS.log(self, :info, "Issues call to ChemSpider for '#{type}' with smiles '#{smiles}'")
      start_time = Time.now

      response = @http_client.get(URL, params, { 'Content-Type' => 'application/json; charset=utf-8' })

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      transaction_id = response.body

      result = wait_for_search_result(transaction_id, result_type)
      query_time = Time.now - start_time

      OPS.log(self, :debug, "(#{transaction_id}) Call took #{query_time} seconds")

      result
    end

    def get_async_search_status(transaction_id)
      response = @http_client.get(URL, { 'op' => 'GetSearchStatus', 'rid' => transaction_id },
                                  { 'Content-Type' => 'application/json; charset=utf-8' })

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      begin
        MultiJson.load(response.body)
      rescue MultiJson::DecodeError
        raise InvalidResponse.new("Could not parse response")
      end
    end

    def get_async_search_result(transaction_id, result_type)
      response = @http_client.get(URL, { 'op' => RESULTS_OPERATIONS[result_type], 'rid' => transaction_id },
                                  { 'Content-Type' => 'application/json; charset=utf-8' })

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      begin
        MultiJson.load(response.body)
      rescue MultiJson::DecodeError
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

        if search_status == "Failed"
          raise Failed.new("ChemSpider returned request status 'Failed'")
        elsif search_status == "TooManyRecords"
          raise TooManyRecords.new("ChemSpider returned request status 'TooManyRecords'")
        end
      end

      result = get_async_search_result(transaction_id, result_type)

      OPS.log(self, :info, "(#{transaction_id}) Search result: #{result}")

      result
    end
  end
end