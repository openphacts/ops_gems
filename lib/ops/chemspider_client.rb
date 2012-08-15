require 'httpclient'
require 'nokogiri'

module OPS
  class ChemspiderClient
    class Error < StandardError; end
    class BadStatusCode < ChemspiderClient::Error; end
    class Unauthorized < ChemspiderClient::Error; end
    class Failed < ChemspiderClient::Error; end
    class TooManyRecords < ChemspiderClient::Error; end
    class InvalidOption < StandardError; end

    STRUCTURE_SEARCH_MATCH_TYPES = {
      :exact_match => 'ExactMatch',
      :all_tautomers => 'AllTautomers',
      :same_skeleton_including_h => 'SameSkeletonIncludingH',
      :same_skeleton_excluding_h => 'SameSkeletonExcludingH',
      :all_isomers => 'AllIsomers'
    }

    def initialize(token, search_status_wait_duration=0.5)
      @token = token
      @search_status_wait_duration = search_status_wait_duration
      @http_client = HTTPClient.new
    end

    def structure_search(smiles, options={})
      options[:match_type] ||= :exact_match

      unless STRUCTURE_SEARCH_MATCH_TYPES.has_key?(options[:match_type])
        raise InvalidOption.new("Value '#{options[:match_type]}' is not valid for option 'match_type'")
      end

      request_body = %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearch xmlns="http://www.chemspider.com/">
      <options>
        <Molecule>#{smiles}</Molecule>
        <MatchType>#{STRUCTURE_SEARCH_MATCH_TYPES[options[:match_type]]}</MatchType>
      </options>
      <token>#{@token}</token>
    </StructureSearch>
  </soap12:Body>
</soap12:Envelope>)

      make_smiles_based_search(request_body, "StructureSearch", smiles)
    end

    def similarity_search(smiles)
      request_body = %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SimilaritySearch xmlns="http://www.chemspider.com/">
      <options>
        <Molecule>#{smiles}</Molecule>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>#{@token}</token>
    </SimilaritySearch>
  </soap12:Body>
</soap12:Envelope>)

      make_smiles_based_search(request_body, "SimilaritySearch", smiles)
    end

    def substructure_search(smiles)
      request_body = %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SubstructureSearch xmlns="http://www.chemspider.com/">
      <options>
        <Molecule>#{smiles}</Molecule>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>#{@token}</token>
    </SubstructureSearch>
  </soap12:Body>
</soap12:Envelope>)

      make_smiles_based_search(request_body, "SubstructureSearch", smiles)
    end

  private
    def make_smiles_based_search(request_body, type, smiles)
      OPS.log(self, :info, "Issues call to ChemSpider for '#{type}' with smiles '#{smiles}'")
      start_time = Time.now

      response = @http_client.post('http://www.chemspider.com/Search.asmx', request_body, 'Content-Type' => 'application/soap+xml; charset=utf-8')

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      if response.body.include?("Unauthorized web service usage. Please request access to this service.")
        raise Unauthorized.new("ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")
      end

      doc = Nokogiri::XML(response.body)
      transaction_id = doc.xpath("//cs:#{type}Response/cs:#{type}Result", "cs" => "http://www.chemspider.com/").first.content

      result = wait_for_search_result(transaction_id)
      query_time = Time.now - start_time

      OPS.log(self, :debug, "(#{transaction_id}) Call took #{query_time} seconds")

      result
    end

    def get_async_search_status(transaction_id)
      response = @http_client.get("http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=#{transaction_id}&token=#{@token}")

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      doc = Nokogiri::XML(response.body)
      doc.xpath("//cs:ERequestStatus", "cs" => "http://www.chemspider.com/").first.content
    end

    def get_async_search_result(transaction_id)
      response = @http_client.get("http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=#{transaction_id}&token=#{@token}")

      raise BadStatusCode.new("Response with status code #{response.code}") if response.code != 200

      doc = Nokogiri::XML(response.body)
      doc.xpath("//cs:ArrayOfInt/cs:int", "cs" => "http://www.chemspider.com/").collect(&:content)
    end

    def wait_for_search_result(transaction_id)
      OPS.log(self, :debug, "(#{transaction_id}) Wait for search result for transaction")

      search_status = nil
      while search_status != "ResultReady" do
        sleep(@search_status_wait_duration) unless search_status.nil?
        search_status = get_async_search_status(transaction_id)
        OPS.log(self, :debug, "(#{transaction_id}) Search status: '#{search_status}'")

        if search_status == "Failed"
          raise Failed.new("ChemSpider returned request status 'Failed'")
        elsif search_status == "TooManyRecords"
          raise TooManyRecords.new("ChemSpider returned request status 'TooManyRecords'")
        end
      end

      result = get_async_search_result(transaction_id)

      OPS.log(self, :info, "(#{transaction_id}) Search result: #{result}")

      result
    end
  end
end