require 'spec_helper'

describe OPS::CoreApiCall do
  before(:all) do
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

  def stub_core_api_request(method, options, url="http://ops.few.vu.nl:9183/opsapi")
    stringified_options = {}
    options.each { |key, value| stringified_options[key.to_s] = value.to_s }

    stringified_options["method"] = method

    stub_request(:post, url).
      with(:body => stringified_options,
            :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'})
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

  it "should set the offset to 0 by default" do
    core_api_call = OPS::CoreApiCall.new
    options = {
      :substring => "Sora",
      :limit => 100
    }

    stubbed_request = stub_core_api_request("compoundLookup", options.merge({:offset => 0})).to_return(@http_response_compound_lookup)

    core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
  end

  it "should set the limit to 100 by default" do
    core_api_call = OPS::CoreApiCall.new
    options = {
      :substring => "Sora",
      :offset => 0
    }

    stubbed_request = stub_core_api_request("compoundLookup", options.merge({:limit => 100})).to_return(@http_response_compound_lookup)

    core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
  end
end
