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

describe OPS::LinkedDataCacheClient, :vcr do
  describe "initialization" do
    it "takes the server URL" do
      OPS::LinkedDataCacheClient.new("http://api.openphacts.org")
    end

    it "raises an ArgumentError if no server URL is given" do
      expect {
        OPS::LinkedDataCacheClient.new
      }.to raise_exception(ArgumentError)
    end

    it "sets the receiving timeout to 60 by default" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(60).once

      OPS::LinkedDataCacheClient.new("http://api.openphacts.org")
    end

    it "uses a defined receiving timeout" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(23).once

      OPS::LinkedDataCacheClient.new("http://api.openphacts.org", :receive_timeout => 23)
    end
  end

  describe "#compound_info" do
    before :each do
      @client = OPS::LinkedDataCacheClient.new("http://api.openphacts.org")
    end

    it "raises an ArgumentError if no compound URI is given" do
      expect {
        @client.compound_info
      }.to raise_exception(ArgumentError)
    end

    it "returns the compound info if the compound is known to OPS" do
      @client.compound_info("http://rdf.chemspider.com/187440").should == {
        :'http://www.chemspider.com' => {
          :uri => "http://rdf.chemspider.com/187440",
          :properties => {
            :smiles => "CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl",
            :inchikey => "MLDQJTXFUGDVEO-UHFFFAOYSA-N",
            :inchi => "InChI=1S/C21H16ClF3N4O3/c1-26-19(30)18-11-15(8-9-27-18)32-14-5-2-12(3-6-14)28-20(31)29-13-4-7-17(22)16(10-13)21(23,24)25/h2-11H,1H3,(H,26,30)(H2,28,29,31)"
          }
        },
        :'http://data.kasabi.com/dataset/chembl-rdf' => {
          :uri => "http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734",
          :properties => {
            :rtb => 6,
            :psa => 92.35,
            :mw_freebase => 464.825,
            :molform => "C21H16ClF3N4O3",
            :hbd => 3,
            :hba => 4,
            :full_mwt => 464.825,
            :alogp => 4.175
          }
        },
        :'http://linkedlifedata.com/resource/drugbank' => {
          :uri => "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398",
          :properties => {
            :toxicity => "The highest dose of sorafenib studied clinically is 800 mg twice daily. The adverse reactions observed at this dose were primarily diarrhea and dermatologic events. No information is available on symptoms of acute overdose in animals because of the saturation of absorption in oral acute toxicity studies conducted in animals.",
            :protein_binding => "99.5%",
            :description => "Sorafenib (rINN), marketed as Nexavar by Bayer, is a drug approved for the treatment of advanced renal cell carcinoma (primary kidney cancer). It has also received \"Fast Track\" designation by the FDA for the treatment of advanced hepatocellular carcinoma (primary liver cancer), and has since performed well in Phase III trials.\nSorafenib is a small molecular inhibitor of Raf kinase, PDGF (platelet-derived growth factor), VEGF receptor 2 & 3 kinases and c Kit the receptor for Stem cell factor. A growing number of drugs target most of these pathways. The originality of Sorafenib lays in its simultaneous targeting of the Raf/Mek/Erk pathway.",
            :biotransformation => "Sorafenib is metabolized primarily in the liver, undergoing oxidative metabolism, mediated by CYP3A4, as well as glucuronidation mediated by UGT1A9. Sorafenib accounts for approximately 70-85% of the circulating analytes in plasma at steady- state. Eight metabolites of sorafenib have been identified, of which five have been detected in plasma. The main circulating metabolite of sorafenib in plasma, the pyridine N-oxide, shows <i>in vitro</i> potency similar to that of sorafenib. This metabolite comprises approximately 9-16% of circulating analytes at steady-state."
          }
        },
          :'http://www.conceptwiki.org' => {
          :uri => "http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5",
          :properties => {
            :pref_label => "Sorafenib"
          }
        }
      }
    end

    it "returns the same result for different URIs of the same known compound" do
      conceptwiki_uri_result = @client.compound_info("http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5")
      chemspider_uri_result = @client.compound_info("http://rdf.chemspider.com/187440")

      conceptwiki_uri_result.should_not be_nil
      chemspider_uri_result.should_not be_nil
      conceptwiki_uri_result.should == chemspider_uri_result
    end

    it "returns nil if the compound is unknown to OPS" do
      @client.compound_info("http://unknown.com/1111").should be_nil
    end

    it "raises an exception if response can't be parsed" do
      stub_request(:get, "http://api.openphacts.org/compound.json?uri=http://unknown.com/1111").
        to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})

      expect {
        @client.compound_info("http://unknown.com/1111")
      }.to raise_exception(OPS::LinkedDataCacheClient::InvalidResponse, "Could not parse response")
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, "http://api.openphacts.org/compound.json?uri=http://unknown.com/1111").
        to_return(:status => 500,
                  :headers => {"Content-Type"=>"application/json; charset=utf-8"})

      expect {
        @client.compound_info("http://unknown.com/1111")
      }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
    end

    it "works with a server URL with trailing backslash" do
      @client = OPS::LinkedDataCacheClient.new("http://api.openphacts.org/")

      @client.compound_info("http://rdf.chemspider.com/187440").should_not be_nil
    end
  end

  describe "#compound_pharmacology" do
    before :each do
      @client = OPS::LinkedDataCacheClient.new("http://api.openphacts.org")
    end

    it "raises an ArgumentError if no compound URI is given" do
      expect {
        @client.compound_targets
      }.to raise_exception(ArgumentError)
    end

    it "works for a known compound with targets" do
      @client.compound_pharmacology("http://rdf.chemspider.com/2157").should_not be_nil
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, "http://api.openphacts.org/compound/pharmacology.json?uri=http://unknown.com/1111").
        to_return(:status => 500,
                  :headers => {"Content-Type"=>"application/json; charset=utf-8"})

      expect {
        @client.compound_pharmacology("http://unknown.com/1111")
      }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
    end

    it "works with a server URL with trailing backslash" do
      @client = OPS::LinkedDataCacheClient.new("http://api.openphacts.org/")
      @client.compound_pharmacology("http://rdf.chemspider.com/6026").should_not be_nil
    end

    it "returns results for using the chemspider URI" do
      uri = 'http://rdf.chemspider.com/2157'
      @client.compound_pharmacology(uri).should_not be_nil
    end

    it "returns results for using the conceptwiki URI" do
      uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
      @client.compound_pharmacology(uri).should_not be_nil
    end

    # it "returns results for using the kasabi/chembl URI" do
    #   uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL25'
    #   @client.compound_pharmacology(uri).should_not be_nil
    # end

    # it "returns results for using the drugbank URI" do
    #   uri = 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
    #   @client.compound_pharmacology(uri).should_not be_nil
    # end

    it "returns results for different URIs (chemspider, conceptwiki) of the same known compound" do
      chembl_uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL25'
      conceptwiki_uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
      chemspider_uri = 'http://rdf.chemspider.com/2157'
      drugbank_uri = 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
      synonymous_uris = [conceptwiki_uri, chemspider_uri]

      results = synonymous_uris.collect{|uri| @client.compound_pharmacology(uri)}
      results.should_not include nil
    end

    it "returns the same result for different URIs (chemspider, conceptwiki) of the same known compound" do
      chembl_uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL25'
      conceptwiki_uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
      chemspider_uri = 'http://rdf.chemspider.com/2157'
      drugbank_uri = 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
      synonymous_uris = [conceptwiki_uri, chemspider_uri]
      
      results = synonymous_uris.collect{|uri| @client.compound_pharmacology(uri)}
      
      results.uniq.size.should be 1
    end


    describe "#compound_targets" do

      it "returns results for different URIs (chemspider, conceptwiki) of the same known compound" do
        chembl_uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL25'
        conceptwiki_uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
        chemspider_uri = 'http://rdf.chemspider.com/2157'
        drugbank_uri = 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
        synonymous_uris = [conceptwiki_uri, chemspider_uri]

        results = synonymous_uris.collect{|uri| @client.compound_targets(uri)}
        results.should_not include nil
      end

      it "returns the same result for different URIs (chemspider, conceptwiki) of the same known compound" do
        chembl_uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL25'
        conceptwiki_uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
        chemspider_uri = 'http://rdf.chemspider.com/2157'
        drugbank_uri = 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
        synonymous_uris = [conceptwiki_uri, chemspider_uri]

        results = synonymous_uris.collect{|uri| @client.compound_targets(uri)}
        results.uniq.size.should be 1
      end

      it "returns nil if the compound is unknown to OPS" do
        @client.compound_targets("http://unknown.com/1111").should be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "http://api.openphacts.org/compound/pharmacology.json?uri=http://unknown.com/1111").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.compound_targets("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::InvalidResponse, "Could not parse response")
      end

      it "works with a server URL with trailing backslash" do
        @client = OPS::LinkedDataCacheClient.new("http://api.openphacts.org/")
        @client.compound_targets("http://rdf.chemspider.com/6026").should_not be_nil
      end

      it "returns a list of uri to title pairs" do
        result = @client.compound_targets("http://rdf.chemspider.com/187440")
        result.should be_an_instance_of(Array)
        elements = result.collect{|e| e.class}
        elements.uniq.size.should be 1
        elements.uniq.first.should be Hash

        elements = result.collect{|e| e.has_key?(:uri)}
        elements.uniq.size.should be 1
        elements.uniq.first.should be true

        elements = result.collect{|e| e.has_key?(:title)}
        elements.uniq.size.should be 1
        elements.uniq.first.should be true
      end

    end
  end

end