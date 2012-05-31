require 'spec_helper'

describe OPS::CoreApiCall do
  before(:all) do
    @default_url = "http://ops.server:9183/opsapi"
    @http_response_compound_lookup = %{HTTP/1.1 200 OK
Date: Tue, 06 Dec 2011 11:21:25 GMT
Accept-Ranges: bytes
Server: Restlet-Framework/2.0.0
Vary: Accept-Charset, Accept-Encoding, Accept-Language, Accept
Content-Length: 690
Content-Type: application/sparql-results+xml; charset=UTF-8

<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<sparql xmlns="http://www.w3.org/2005/sparql-results#">
  <head>
    <variable name="compound_uri"/>
    <variable name="compound_name"/>
  </head>
  <results>
    <result>
      <binding name="compound_uri">
        <uri>http://rdf.chemspider.com/187440</uri>
      </binding>
      <binding name="compound_name">
        <literal>Sorafenib</literal>
      </binding>
    </result>
    <result>
      <binding name="compound_uri">
        <uri>http://rdf.chemspider.com/3971</uri>
      </binding>
      <binding name="compound_name">
        <literal>8-Methoxypsoralen</literal>
      </binding>
    </result>
  </results>
</sparql>}
  end

  def stub_core_api_request(method, options, url=nil)
    stringified_options = {}
    options.each { |key, value| stringified_options[key.to_s] = value.to_s }
    url ||= @default_url

    stringified_options = { "offset" => "0", "limit" => "100" }.merge(stringified_options)
    stringified_options["method"] = method

    stub_request(:post, url).
      with(:body => stringified_options, :headers => {'Content-Type'=>'application/x-www-form-urlencoded'})
  end

  it "calls the OPS core API with all specified options and parses the result" do
    core_api_call = OPS::CoreApiCall.new("http://myserver:1234/opsapi")
    options = {
      :substring => "Sora",
      :limit => 2,
      :offset => 3
    }

    stubbed_request = stub_core_api_request("compoundLookup", options, "http://myserver:1234/opsapi").to_return(@http_response_compound_lookup)

    results = core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
    results.should == [
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"}]
  end

  it "sets the offset to 0 by default" do
    core_api_call = OPS::CoreApiCall.new(@default_url)
    options = {
      :substring => "Sora",
      :limit => 100
    }

    stubbed_request = stub_core_api_request("compoundLookup", options.merge({:offset => 0})).to_return(@http_response_compound_lookup)

    core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
  end

  it "sets the limit to 100 by default" do
    core_api_call = OPS::CoreApiCall.new(@default_url)
    options = {
      :substring => "Sora",
      :offset => 0
    }

    stubbed_request = stub_core_api_request("compoundLookup", options.merge({:limit => 100})).to_return(@http_response_compound_lookup)

    core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
  end

  it "calls ChemSpider directly for the method 'chemicalExactStructureSearch' and redirects the call to the method 'compoundInfo'" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


    core_api_call = OPS::CoreApiCall.new(@default_url)
    stubbed_request = stub_core_api_request("compoundInfo", { :uri => "<http://rdf.chemspider.com/2157>" }).to_return(@http_response_compound_lookup)

    results = core_api_call.request("chemicalExactStructureSearch",
                                    :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                                    :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")

    stubbed_request.should have_been_made.once
    results.should == [
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"}]
  end

  it "calls ChemSpider directly for the method 'chemicalSimilaritySearch' and redirects the call to the method 'compoundInfo'" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
  <int>123</int>
</ArrayOfInt>))


    core_api_call = OPS::CoreApiCall.new(@default_url)
    stubbed_request = stub_core_api_request("compoundInfo", { :uri => "<http://rdf.chemspider.com/2157>" }).to_return(@http_response_compound_lookup)
    stubbed_request2 = stub_core_api_request("compoundInfo", { :uri => "<http://rdf.chemspider.com/123>" }).to_return(@http_response_compound_lookup)

    results = core_api_call.request("chemicalSimilaritySearch",
                                    :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                                    :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")

    stubbed_request.should have_been_made.once
    stubbed_request2.should have_been_made.once
    results.should == [
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"},
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"}]
  end

  it "calls ChemSpider directly for the method 'chemicalSubstructureSearch' and redirects the call to the method 'compoundInfo'" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
</ArrayOfInt>))


    core_api_call = OPS::CoreApiCall.new(@default_url)
    results = core_api_call.request("chemicalSubstructureSearch",
                                    :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                                    :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")


    results.should == []
  end

  it "waits until a result from ChemSpider is available" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    expected_requests = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


    core_api_call = OPS::CoreApiCall.new(@default_url)
    stubbed_request = stub_core_api_request("compoundInfo", { :uri => "<http://rdf.chemspider.com/2157>" }).to_return(@http_response_compound_lookup)

    results = core_api_call.request("chemicalExactStructureSearch",
                                    :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                                    :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")

    expected_requests.should have_been_made.times(7)
    stubbed_request.should have_been_made.once
    results.should == [
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"}]
  end

  it "raises an exception if ChemSpider returns the request status 'Failed'" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">Failed</ERequestStatus>))

    expect do
      core_api_call = OPS::CoreApiCall.new(@default_url)
      core_api_call.request("chemicalExactStructureSearch",
                            :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                            :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
    end.to raise_error(OPS::ChemSpiderClient::Failed, "ChemSpider returned request status 'Failed'")
  end

  it "raises an exception if ChemSpider returns the request status 'TooManyRecords'" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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

    stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">TooManyRecords</ERequestStatus>))

    expect do
      core_api_call = OPS::CoreApiCall.new(@default_url)
      core_api_call.request("chemicalExactStructureSearch",
                            :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                            :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
    end.to raise_error(OPS::ChemSpiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")
  end

  it "raises an exception on unauthorized ChemSpider web service usage" do
    stub_request(:post, "http://www.chemspider.com/Search.asmx").
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
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<soap:Body>
 <soap:Fault>
   <soap:Code>
     <soap:Value>soap:Sender</soap:Value>
   </soap:Code>
   <soap:Reason>
     <soap:Text xml:lang="en">
       Unauthorized web service usage. Please request access to this service. ---&gt; Unauthorized web service usage. Please request access to this service.
     </soap:Text>
   </soap:Reason>
   <soap:Detail />
 </soap:Fault>
</soap:Body>
</soap:Envelope>),
                   :headers => {'Content-Type'=>'application/soap+xml; charset=utf-8'})

    expect do
      core_api_call = OPS::CoreApiCall.new(@default_url)
      core_api_call.request("chemicalExactStructureSearch",
                            :smiles => "CC(=O)Oc1ccccc1C(=O)O",
                            :chemspider_token => "00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
    end.to raise_error(OPS::ChemSpiderClient::Unauthorized, "ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")
  end
end
