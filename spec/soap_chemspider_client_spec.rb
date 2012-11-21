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

require 'spec_helper'

describe OPS::SoapChemspiderClient do
  describe "#structure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
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

      chemspider_client = OPS::SoapChemspiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa", 0)
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Failed, "ChemSpider returned request status 'Failed'")

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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception on unauthorized ChemSpider web service usage" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Unauthorized, "ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")

      expected_search_request.should have_been_made.once
    end

    it "can search with match type 'exact_match'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
         with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :exact_match)

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "can search with match type 'all_tautomers'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
         with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <MatchType>AllTautomers</MatchType>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :all_tautomers)

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "can search with match type 'same_skeleton_including_h'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
         with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <MatchType>SameSkeletonIncludingH</MatchType>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :same_skeleton_including_h)

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "can search with match type 'same_skeleton_excluding_h'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
         with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <MatchType>SameSkeletonExcludingH</MatchType>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :same_skeleton_excluding_h)

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "can search with match type 'all_isomers'" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
         with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <StructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <MatchType>AllIsomers</MatchType>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
         to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
      results = chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :all_isomers)

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      results.should == ["2157"]
    end

    it "raises an exception if an unknown match type gets used" do
      expect do
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O", :match_type => :unknown_bla)
      end.to raise_error(OPS::SoapChemspiderClient::InvalidOption, "Value 'unknown_bla' is not valid for option 'match_type'")
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:post, "http://www.chemspider.com/Search.asmx").
        to_return(:status => 500)

      expect {
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.structure_search("CC(=O)Oc1ccccc1C(=O)O")
      }.to raise_exception(OPS::SoapChemspiderClient::BadStatusCode, "Response with status code 500")
    end
  end

  describe "#similarity_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
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

      chemspider_client = OPS::SoapChemspiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa", 0)
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Failed, "ChemSpider returned request status 'Failed'")

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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception on unauthorized ChemSpider web service usage" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SimilaritySearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <SimilarityType>Tanimoto</SimilarityType>
        <Threshold>0.99</Threshold>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SimilaritySearch>
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Unauthorized, "ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")

      expected_search_request.should have_been_made.once
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:post, "http://www.chemspider.com/Search.asmx").
        to_return(:status => 503)

      expect {
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      }.to raise_exception(OPS::SoapChemspiderClient::BadStatusCode, "Response with status code 503")
    end
  end

  describe "#substructure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
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

      expected_status_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchStatus?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ERequestStatus xmlns="http://www.chemspider.com/">ResultReady</ERequestStatus>))

      expected_result_request = stub_request(:get, "http://www.chemspider.com/Search.asmx/GetAsyncSearchResult?rid=9629dbb8-0ca2-4884-aa8b-f4e7f521e25f&token=00000000-aaaa-2222-bbbb-aaa2ccc00000aa").
           to_return(:status => 200, :body => %(<?xml version="1.0" encoding="utf-8"?>
<ArrayOfInt xmlns="http://www.chemspider.com/">
  <int>2157</int>
</ArrayOfInt>))


      chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
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

      chemspider_client = OPS::SoapChemspiderClient.new("00000000-CCCC-2222-bbbb-aaa2ccc00000aa", 0)
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Failed, "ChemSpider returned request status 'Failed'")

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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::TooManyRecords, "ChemSpider returned request status 'TooManyRecords'")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.once
    end

    it "raises an exception on unauthorized ChemSpider web service usage" do
      expected_search_request = stub_request(:post, "http://www.chemspider.com/Search.asmx").
           with(:body => %(<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\">
  <soap12:Body>
    <SubstructureSearch xmlns=\"http://www.chemspider.com/\">
      <options>
        <Molecule>CC(=O)Oc1ccccc1C(=O)O</Molecule>
        <MatchTautomers>false</MatchTautomers>
      </options>
      <token>00000000-aaaa-2222-bbbb-aaa2ccc00000aa</token>
    </SubstructureSearch>
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
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      end.to raise_error(OPS::SoapChemspiderClient::Unauthorized, "ChemSpider returned 'Unauthorized web service usage. Please request access to this service.'")

      expected_search_request.should have_been_made.once
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:post, "http://www.chemspider.com/Search.asmx").
        to_return(:status => 504)

      expect {
        chemspider_client = OPS::SoapChemspiderClient.new("00000000-aaaa-2222-bbbb-aaa2ccc00000aa")
        chemspider_client.substructure_search("CC(=O)Oc1ccccc1C(=O)O")
      }.to raise_exception(OPS::SoapChemspiderClient::BadStatusCode, "Response with status code 504")
    end
  end
end
