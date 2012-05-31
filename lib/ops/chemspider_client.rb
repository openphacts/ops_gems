require 'nokogiri'

module OPS
  class ChemSpiderClient
    class Error < StandardError; end
    class Unauthorized < ChemSpiderClient::Error; end
    class Failed < ChemSpiderClient::Error; end
    class TooManyRecords < ChemSpiderClient::Error; end

    def initialize(token)
      @token = token
    end

    def structure_search(smiles)
      request_body = %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearch xmlns="http://www.chemspider.com/">
      <options>
        <Molecule>#{smiles}</Molecule>
        <SearchType>ExactMatch</SearchType>
        <MatchType>ExactMatch</MatchType>
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
        <SearchType>Similarity</SearchType>
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
        <SearchType>Substructure</SearchType>
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
      uri = URI.parse("http://www.chemspider.com/Search.asmx")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/soap+xml; charset=utf-8"
      request.body = request_body

      OPS.log(self, :info, "Issues call to ChemSpider for '#{type}' with smiles '#{smiles}'")
      start_time = Time.now

      response = nil
      http.start do |http|
        response = http.request(request)
      end

      if response.body.include?("Unauthorized web service usage. Please request access to this service.")
        raise Unauthorized.new("ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")
      end

      doc = Nokogiri::XML(response.body)
      transaction_id = doc.xpath("//cs:#{type}Response/cs:#{type}Result", "cs" => "http://www.chemspider.com/").first.content

      query_time = Time.now - start_time
      OPS.log(self, :debug, "(#{transaction_id}) Call took #{query_time} seconds")

      wait_for_search_result(transaction_id)
    end

    def get_async_search_status(transaction_id)
      response = Net::HTTP.get_response(URI.parse("http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=#{transaction_id}&token=#{@token}"))
      doc = Nokogiri::XML(response.body)
      doc.xpath("//cs:ERequestStatus", "cs" => "http://www.chemspider.com/").first.content
    end

    def get_async_search_result(transaction_id)
      response = Net::HTTP.get_response(URI.parse("http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=#{transaction_id}&token=#{@token}"))
      doc = Nokogiri::XML(response.body)
      doc.xpath("//cs:ArrayOfInt/cs:int", "cs" => "http://www.chemspider.com/").collect(&:content)
    end

    def wait_for_search_result(transaction_id)
      OPS.log(self, :debug, "(#{transaction_id}) Wait for search result for transaction")

      search_status = nil
      while search_status != "ResultReady" do
        sleep(0.5) unless search_status.nil?
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