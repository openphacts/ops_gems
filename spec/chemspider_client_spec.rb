require 'spec_helper'

describe OPS::ChemSpiderClient do
  describe "structure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>ExactMatch</SearchType>
        <MatchType>ExactMatch</MatchType>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </StructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/soap+xml; charset=utf-8', 'User-Agent'=>'Ruby'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearchResponse xmlns="http://www.chemspider.com/">
      <StructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</StructureSearchResult>
    </StructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CCCCCC</Molecule>
        <SearchType>ExactMatch</SearchType>
        <MatchType>ExactMatch</MatchType>
      </options>
      <token>00000000-CCCC-2222-bbbb-aaa2ccc00000aa</token>
    </StructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearchResponse xmlns="http://www.chemspider.com/">
      <StructureSearchResult>9629dbb8-AAAA-4884-aa8b-f4e7f521e25f</StructureSearchResult>
    </StructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return({:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Unknown</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Created</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Scheduled</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Processing</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Suspended</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">PartialResultReady</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>)})

      expected_result_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>3344</int>
</ArrayOfInt>))

      chemspider_client = OPS::ChemSpiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CCCCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_requests.should have_been_made.once

      results.should == ["3344"]
    end

    it "raises an exception if ChemSpider returns the request status 'Failed'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>ExactMatch</SearchType>
        <MatchType>ExactMatch</MatchType>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </StructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearchResponse xmlns="http://www.chemspider.com/">
      <StructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</StructureSearchResult>
    </StructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Failed</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::Failed, "ChemSpider returned request status 'Failed'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception if ChemSpider returns the request status 'TooManyRecords'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>ExactMatch</SearchType>
        <MatchType>ExactMatch</MatchType>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </StructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <StructureSearchResponse xmlns="http://www.chemspider.com/">
      <StructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</StructureSearchResult>
    </StructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">TooManyRecords</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end
  end

  describe "similarity_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Similarity</SearchType>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SimilaritySearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/soap+xml; charset=utf-8', 'User-Agent'=>'Ruby'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SimilaritySearchResponse xmlns="http://www.chemspider.com/">
      <SimilaritySearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SimilaritySearchResult>
    </SimilaritySearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CCCCCC</Molecule>
        <SearchType>Similarity</SearchType>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>00000000-CCCC-2222-bbbb-aaa2ccc00000aa</token>
    </SimilaritySearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SimilaritySearchResponse xmlns="http://www.chemspider.com/">
      <SimilaritySearchResult>9629dbb8-AAAA-4884-aa8b-f4e7f521e25f</SimilaritySearchResult>
    </SimilaritySearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return({:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Unknown</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Created</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Scheduled</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Processing</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Suspended</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">PartialResultReady</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>)})

      expected_result_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>3344</int>
</ArrayOfInt>))

      chemspider_client = OPS::ChemSpiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.similarity_search("CCCCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_requests.should have_been_made.once

      results.should == ["3344"]
    end

    it "raises an exception if ChemSpider returns the request status 'Failed'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Similarity</SearchType>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SimilaritySearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SimilaritySearchResponse xmlns="http://www.chemspider.com/">
      <SimilaritySearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SimilaritySearchResult>
    </SimilaritySearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Failed</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::Failed, "ChemSpider returned request status 'Failed'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception if ChemSpider returns the request status 'TooManyRecords'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Similarity</SearchType>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SimilaritySearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SimilaritySearchResponse xmlns="http://www.chemspider.com/">
      <SimilaritySearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SimilaritySearchResult>
    </SimilaritySearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">TooManyRecords</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end
  end

  describe "substructure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Substructure</SearchType>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SubstructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/soap+xml; charset=utf-8', 'User-Agent'=>'Ruby'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SubstructureSearchResponse xmlns="http://www.chemspider.com/">
      <SubstructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SubstructureSearchResult>
    </SubstructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CCCCCC</Molecule>
        <SearchType>Substructure</SearchType>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>00000000-CCCC-2222-bbbb-aaa2ccc00000aa</token>
    </SubstructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SubstructureSearchResponse xmlns="http://www.chemspider.com/">
      <SubstructureSearchResult>9629dbb8-AAAA-4884-aa8b-f4e7f521e25f</SubstructureSearchResult>
    </SubstructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return({:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Unknown</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Created</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Scheduled</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Processing</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Suspended</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">PartialResultReady</ERequestStatus>)},
                     {:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>)})

      expected_result_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-AAAA-4884-aa8b-f4e7f521e25f&token=00000000-CCCC-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>3344</int>
</ArrayOfInt>))

      chemspider_client = OPS::ChemSpiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.substructure_search("CCCCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_requests.should have_been_made.once

      results.should == ["3344"]
    end

    it "raises an exception if ChemSpider returns the request status 'Failed'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Substructure</SearchType>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SubstructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SubstructureSearchResponse xmlns="http://www.chemspider.com/">
      <SubstructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SubstructureSearchResult>
    </SubstructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Failed</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::Failed, "ChemSpider returned request status 'Failed'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception if ChemSpider returns the request status 'TooManyRecords'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SearchType>Substructure</SearchType>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SubstructureSearch>
  </soap12:Body>
</soap12:Envelope>),
                :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'}).
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <SubstructureSearchResponse xmlns="http://www.chemspider.com/">
      <SubstructureSearchResult>9629dbb8-0ca2-4884-aa8b-f4e7f521e25f</SubstructureSearchResult>
    </SubstructureSearchResponse>
  </soap12:Body>
</soap12:Envelope>),
                     :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

      expected_status_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">TooManyRecords</ERequestStatus>))

      expect do
        chemspider_client = OPS::ChemSpiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        results = chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::ChemSpiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end
  end
end
