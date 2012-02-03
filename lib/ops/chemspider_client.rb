require 'nokogiri'

module OPS
  class ChemSpiderClient
    class Error < StandardError; end
    class Failed < ChemSpiderClient::Error; end
    class TooManyRecords < ChemSpiderClient::Error; end

    def initialize(token)
      @token = token
    end

    def structure_search(smiles)
      uri = URI.parse("http://www.chemspider.com/Search.asmx")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/soap+xml; charset=utf-8"
      request.body = %(<?xml version="1.0" encoding="utf-8"?>
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
      response = nil

      OPS.log(self, "Issues call to ChemSpider for 'StructureSearch' with smiles '#{smiles}'")
      start_time = Time.now

      http.start do |http|
        response = http.request(request)
      end

      doc = Nokogiri::XML(response.body)
      transaction_id = doc.xpath("//cs:StructureSearchResponse/cs:StructureSearchResult", "cs" => "http://www.chemspider.com/").first.content

      query_time = Time.now - start_time
      OPS.log(self, "(#{transaction_id}) Call took #{query_time} seconds")

      wait_for_search_result(transaction_id)
    end

    def similarity_search(smiles)
      uri = URI.parse("http://www.chemspider.com/Search.asmx")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/soap+xml; charset=utf-8"
      request.body = %(<?xml version="1.0" encoding="utf-8"?>
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
      response = nil

      OPS.log(self, "Issues call to ChemSpider for 'SimilaritySearch' with smiles '#{smiles}'")
      start_time = Time.now

      http.start do |http|
        response = http.request(request)
      end

      doc = Nokogiri::XML(response.body)
      transaction_id = doc.xpath("//cs:SimilaritySearchResponse/cs:SimilaritySearchResult", "cs" => "http://www.chemspider.com/").first.content

      query_time = Time.now - start_time
      OPS.log(self, "(#{transaction_id}) Call took #{query_time} seconds")

      wait_for_search_result(transaction_id)
    end

    def substructure_search(smiles)
      uri = URI.parse("http://www.chemspider.com/Search.asmx")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/soap+xml; charset=utf-8"
      request.body = %(<?xml version="1.0" encoding="utf-8"?>
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
      response = nil

      OPS.log(self, "Issues call to ChemSpider for 'SubstructureSearch' with smiles '#{smiles}'")
      start_time = Time.now

      http.start do |http|
        response = http.request(request)
      end

      doc = Nokogiri::XML(response.body)
      transaction_id = doc.xpath("//cs:SubstructureSearchResponse/cs:SubstructureSearchResult", "cs" => "http://www.chemspider.com/").first.content

      query_time = Time.now - start_time
      OPS.log(self, "(#{transaction_id}) Call took #{query_time} seconds")

      wait_for_search_result(transaction_id)
    end

  private
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
      OPS.log(self, "(#{transaction_id}) Wait for search result for transaction")

      search_status = nil
      while search_status != "ResultReady" do
        sleep(0.5) unless search_status.nil?
        search_status = get_async_search_status(transaction_id)
        OPS.log(self, "(#{transaction_id}) Search status: '#{search_status}'")

        if search_status == "Failed"
          raise Failed.new("ChemSpider returned request status 'Failed'")
        elsif search_status == "TooManyRecords"
          raise TooManyRecords.new("ChemSpider returned request status 'TooManyRecords'")
        end
      end

      result = get_async_search_result(transaction_id)

      OPS.log(self, "(#{transaction_id}) Search result: #{result}")

      result
    end
  end
end