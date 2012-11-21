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
  describe "#exact_exact_structure_search" do
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
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

      chemspider_client = OPS::JsonChemspiderClient.new(0)
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
    it "returns the result from ChemSpider" do
      expected_search_request = stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'SimilaritySearch',
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)OCCC",
              'searchOptions.SimilarityType' => 'Tanimoto',
              'searchOptions.Threshold' => 0.99,
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
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
        with(:query => {
              'op' => 'SimilaritySearch',
              'searchOptions.Molecule' => "CCCCCC",
              'searchOptions.SimilarityType' => 'Tanimoto',
              'searchOptions.Threshold' => 0.99,
              'scopeOptions.DataSources[0]' => 'DrugBank',
              'scopeOptions.DataSources[1]' => 'ChEMBL',
              'scopeOptions.DataSources[2]' => 'ChEBI',
              'scopeOptions.DataSources[3]' => 'PDB',
              'scopeOptions.DataSources[4]' => 'MeSH'
            },
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

      chemspider_client = OPS::JsonChemspiderClient.new(0)
      result = chemspider_client.similarity_search("CCCCCC")

      expected_search_request.should have_been_made.once
      expected_status_requests.should have_been_made.times(7)
      expected_result_request.should have_been_made.once

      result.should == [112]
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'SimilaritySearch',
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'searchOptions.SimilarityType' => 'Tanimoto',
              'searchOptions.Threshold' => 0.99,
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
        chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O")
      }.to raise_exception(OPS::JsonChemspiderClient::BadStatusCode, "Response with status code 504")
    end

    it "uses a given threshold" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'SimilaritySearch',
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'searchOptions.SimilarityType' => 'Tanimoto',
              'searchOptions.Threshold' => 0.73,
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
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O", :threshold => 0.73)

      result.should == [2157]
    end

    it "can return the result as compound data hashes" do
      stub_request(:get, 'http://www.chemspider.com/JSON.ashx').
        with(:query => {
              'op' => 'SimilaritySearch',
              'searchOptions.Molecule' => "CC(=O)Oc1ccccc1C(=O)O",
              'searchOptions.SimilarityType' => 'Tanimoto',
              'searchOptions.Threshold' => 0.99,
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
      result = chemspider_client.similarity_search("CC(=O)Oc1ccccc1C(=O)O", :result_type => :compounds)

      result.should == [{"CSID" => 2157}]
    end
  end
end
