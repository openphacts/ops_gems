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

describe OPS::JsonChemspiderClient do
  before :each do
    @limit = 1000
  end

  describe "#substructure_search" do
    before :each do
      @query = {
        'op' => 'SubstructureSearch',
        'limit' => @limit,
        'searchOptions.MatchTautomers' => 'false',
        'searchOptions.Molecule' => "CC=CC=COC=CC=CC",
        'scopeOptions.DataSources[0]' => 'DrugBank',
        'scopeOptions.DataSources[1]' => 'ChEMBL',
        'scopeOptions.DataSources[2]' => 'ChEBI',
        'scopeOptions.DataSources[3]' => 'PDB',
        'scopeOptions.DataSources[4]' => 'MeSH'
      }
    end

    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052, 4946325, 4953135, 10176672, 21376080]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC')

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      result.should == [3453052, 4946325, 4953135, 10176672, 21376080]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_requests = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return({ :status => 200, :body => %({"Count":1,"Elapsed":"PT0.103S","Message":"Unknown","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT1.103S","Message":"Created","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Scheduled","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT3.103S","Message":"Processing","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT4.103S","Message":"Suspended","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"PartialResultReady","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"Finished","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }})

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052, 4946325, 4953135, 10176672, 21376080]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new(@limit, 0)
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC')

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_request.should have_been_made.once

      result.should == [3453052, 4946325, 4953135, 10176672, 21376080]
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 504)

      expect {
        chemspider_client = OPS::JsonChemspiderClient.new
        chemspider_client.substructure_search('CC=CC=COC=CC=CC')
      }.to raise_exception(OPS::JsonChemspiderClient::BadStatusCode, 'Response with status code 504')
    end

    it "can return the result as compound data hashes" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResultAsCompounds', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([{"CSID": 3333}]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :result_type => :compounds)

      result.should == [{"CSID" => 3333}]
    end

    it 'accepts and applies the :limit parameter' do
      query = @query.merge({'limit' => 1})
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :limit => 1)
      expected_search_request.should have_been_made.once
    end

    it 'uses :match_tautomers = false as default' do
      query = @query.merge({'searchOptions.MatchTautomers' => 'false'})
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC')
      expected_search_request.should have_been_made.once
    end

    it 'overwrites invalid :match_tautomers parameter value with false' do
      query = @query.merge({'searchOptions.MatchTautomers' => 'false'})
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :match_tautomers => 'invalid')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :match_tautomers = true' do
      query = @query.merge({'searchOptions.MatchTautomers' => 'true'})
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :match_tautomers => true)
      expected_search_request.should have_been_made.once
    end

    it 'ignores invalid :complexity parameter values' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :complexity => 'invalid')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :complexity = "any"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Complexity' => 'Any'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :complexity => 'any')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :complexity = "single"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Complexity' => 'Single'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :complexity => 'single')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :complexity = "multi"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Complexity' => 'Multi'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :complexity => 'multi')
      expected_search_request.should have_been_made.once
    end

    it 'ignores invalid :isotopic parameter values' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :isotopic => 'invalid')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :isotopic = "any"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Isotopic' => 'Any'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :isotopic => 'any')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :isotopic = "labeled"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Isotopic' => 'Labeled'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :isotopic => 'labeled')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :isotopic = "not_labeled"' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Isotopic' => 'NotLabeled'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :isotopic => 'not_labeled')
      expected_search_request.should have_been_made.once
    end

    it 'ignores invalid :has_spectra parameter values' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_spectra => 'invalid')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :has_spectra = true' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.HasSpectra' => 'true'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_spectra => true)
      expected_search_request.should have_been_made.once
    end

    it 'accepts :has_spectra = false' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.HasSpectra' => 'false'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_spectra => false)
      expected_search_request.should have_been_made.once
    end

    it 'ignores invalid :has_patents parameter values' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_patents => 'invalid')
      expected_search_request.should have_been_made.once
    end

    it 'accepts :has_patents = true' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.HasPatents' => 'true'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_patents => true)
      expected_search_request.should have_been_made.once
    end

    it 'accepts :has_patents = false' do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.HasPatents' => 'false'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":5,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3453052]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.substructure_search('CC=CC=COC=CC=CC', :has_patents => false)
      expected_search_request.should have_been_made.once
    end



  end

  describe "#exact_estructure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'limit' => @limit,
              'op' => 'ExactStructureSearch',
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.exact_structure_search("CC(=O)Oc1ccccc1C(=O)O")

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      result.should == [2157]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'ExactStructureSearch',
              'limit' => @limit,
              'searchOptions.Molecule' => "CCCCCC",
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_requests = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return({ :status => 200, :body => %({"Count":1,"Elapsed":"PT0.103S","Message":"Unknown","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT1.103S","Message":"Created","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Scheduled","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT3.103S","Message":"Processing","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT4.103S","Message":"Suspended","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"PartialResultReady","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"Finished","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }})

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([3344]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new(@limit, 0)
      result = chemspider_client.exact_structure_search("CCCCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_request.should have_been_made.once

      result.should == [3344]
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'ExactStructureSearch',
              'limit' => @limit,
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 504)

      expect {
        chemspider_client = OPS::JsonChemspiderClient.new
        chemspider_client.exact_structure_search("CC(=O)Oc1ccccc1C(=O)O")
      }.to raise_exception(OPS::JsonChemspiderClient::BadStatusCode, "Response with status code 504")
    end

    it "can return the result as compound data hashes" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'ExactStructureSearch',
              'limit' => @limit,
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResultAsCompounds', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([{"CSID": 3333}]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.exact_structure_search("CC(=O)Oc1ccccc1C(=O)O", :result_type => :compounds)

      result.should == [{"CSID" => 3333}]
    end
  end

  describe "#similarity_search" do
    before :each do
      @query = {
        'op' => 'SimilaritySearch',
        'limit' => @limit,
        'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)OCCC",
        'searchOptions.SimilarityType' => 'Tanimoto',
        'searchOptions.Threshold' => 0.99,
        'scopeOptions.DataSources[0]' => 'DrugBank',
        'scopeOptions.DataSources[1]' => 'ChEMBL',
        'scopeOptions.DataSources[2]' => 'ChEBI',
        'scopeOptions.DataSources[3]' => 'PDB',
        'scopeOptions.DataSources[4]' => 'MeSH'
      }
    end

    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-1111-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'application/soap+xml; charset=utf-8' })

      expected_status_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-1111-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}))

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-1111-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([8888, 213]))


      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC")

      expected_search_request.should have_been_made.once
      expected_status_request.should have_been_made.once
      expected_result_request.should have_been_made.once

      result.should == [8888, 213]
    end

    it "waits until a result from ChemSpider is available" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'application/soap+xml; charset=utf-8' })

      expected_status_requests = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return({ :status => 200, :body => %({"Count":1,"Elapsed":"PT0.103S","Message":"Unknown","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT1.103S","Message":"Created","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Scheduled","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT3.103S","Message":"Processing","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT4.103S","Message":"Suspended","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"PartialResultReady","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }},
                      { :status => 200, :body => %({"Count":1,"Elapsed":"PT5.103S","Message":"Finished","Progress":1,"Status":6}),
                        :headers => { 'Content-Type' => 'text/plain' }})

      expected_result_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-AAAA-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([112]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new(@limit, 0)
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_request.should have_been_made.once

      result.should == [112]
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 504)

      expect {
        chemspider_client = OPS::JsonChemspiderClient.new
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC")
      }.to raise_exception(OPS::JsonChemspiderClient::BadStatusCode, "Response with status code 504")
    end

    it "accepts and applies the :threshold parameter" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Threshold' => 0.73}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :threshold => 0.73)
    end

    it "uses 'Tanimoto' as default :similarity_type" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Threshold' => 0.73}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :threshold => 0.73, :similarity_type => 'invalid')
    end

    it "accepts :similarity_type = 'Tversky'" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Threshold' => 0.73, 'searchOptions.SimilarityType' => 'Tversky'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :threshold => 0.73, :similarity_type => 'Tversky')
    end

    it "accepts :similarity_type = 'Euclidian'" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Threshold' => 0.73, 'searchOptions.SimilarityType' => 'Euclidian'}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :threshold => 0.73, :similarity_type => 'Euclidian')
    end

    it "overwrites an invalid :similarity_type with 'Tanimoto'" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query.merge({'searchOptions.Threshold' => 0.73}),
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResult', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([2157]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :threshold => 0.73, :similarity_type => 'invalid')
    end

    it "can return the result as compound data hashes" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => @query,
            :body => '',
            :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
          to_return(:status => 200, :body => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f',
                    :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
          with(:query => { 'op' => 'GetSearchStatus', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                :body => '',
                :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
            to_return(:status => 200, :body => %({"Count":1,"Elapsed":"PT2.103S","Message":"Finished","Progress":1,"Status":6}),
                      :headers => { 'Content-Type' => 'text/plain' })

      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
                with(:query => { 'op' => 'GetSearchResultAsCompounds', 'rid' => '9629dbb8-0ca2-4884-aa8b-f4e7f521e25f' },
                      :body => '',
                      :headers => { 'Content-Type' => 'application/json; charset=utf-8' }).
                  to_return(:status => 200, :body => %([{"CSID": 2157}]),
                            :headers => { 'Content-Type' => 'text/plain' })

      chemspider_client = OPS::JsonChemspiderClient.new
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)OCCC", :result_type => :compounds)

      result.should == [{"CSID" => 2157}]
    end
  end
end
