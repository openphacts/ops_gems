require 'spec_helper'

describe CoreApiCall do
  it "calls the OPS core API and parses the result" do
    stubbed_request = stub_request(:post, "http://ops.few.vu.nl:9183/opsapi").
         with(:body => {"method"=>"compoundLookup", "substring"=>"Sora", "limit"=>"2", "offset"=>"0"},
              :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(%{HTTP/1.1 200 OK
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
</sparql>})

    core_api_call = CoreApiCall.new
    options = Hash.new
    options[:substring] = "Sora"
    options[:limit] = 2
    results = core_api_call.request("compoundLookup", options)

    stubbed_request.should have_been_made.once
    results.should == [
      {:compound_uri=>"http://rdf.chemspider.com/187440", :compound_name=>"Sorafenib"},
      {:compound_uri=>"http://rdf.chemspider.com/3971", :compound_name=>"8-Methoxypsoralen"}]
  end
end
