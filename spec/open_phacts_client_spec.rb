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

OPS_SETTINGS = {
  :url => 'https://beta.openphacts.org/1.4',
  :app_id => 'secret_id',
  :app_key => 'secret_key'
}.freeze

VALID_COMPOUND_URI  = 'http://ops.rsc.org/OPS3'
VALID_TARGET_URI    = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
INVALID_URI         = '#187440'
UNKNOWN_URI         = 'http://unknown.com/1111'
VALID_SMILES        = 'CC(=O)Oc1ccccc1C(=O)O'
INVALID_SMILES      = 'CCC)'
UNKNOWN_SMILES      = 'N1NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN1'


describe OPS::OpenPhactsClient, :vcr do
  describe "initialization" do
    before :each do
      @config = {:url => 'https://www.url.com', :app_id => 'app_id', :app_key => 'app_key'}
    end

    it "accepts a config hash" do
      OPS::OpenPhactsClient.new(@config)
    end

    it "raises an ArgumentError if no server settings are given" do
      expect {
        OPS::OpenPhactsClient.new
      }.to raise_error(ArgumentError)
    end

    it "raises an OPS::MissingArgument if server url is missing" do
      @config.delete(:url)
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "raises an OPS::MissingArgument if an empty server url is given" do
      @config[:url] = ''
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "raises an OPS::InvalidArgument if an invalid server url is given" do
      @config[:url] = 'ptth:\\as.de'
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::InvalidArgument)
    end

    it "raises an OPS::MissingArgument if app_id is missing" do
      @config.delete(:app_id)
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "raises an OPS::MissingArgument if an empty app_id is given" do
      @config[:app_id] = ''
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "raises an OPS::MissingArgument if app_key is missing" do
      @config.delete(:app_key)
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "raises an OPS::MissingArgument if an empty app_key is given" do
      @config[:app_key] = ''
      expect {
        OPS::OpenPhactsClient.new(@config)
      }.to raise_error(OPS::MissingArgument)
    end

    it "sets the receiving timeout to 60 by default" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(60).once
      OPS::OpenPhactsClient.new(@config)
    end

    it "uses a defined receiving timeout" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(23).once
      OPS::OpenPhactsClient.new(@config, :receive_timeout => 23)
    end
  end



  describe 'any query' do
    context 'with invalid app id/key' do
      before :each do
        @config = OPS_SETTINGS.dup
        @config[:app_id] = 'foo'
        @config[:app_key] = 'bar'
        @client = OPS::OpenPhactsClient.new(@config)
      end

      it 'raises ForbiddenError (403)' do
        expect {@client.compound_info(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.compound_info_batch(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.compound_pharmacology(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.compound_pharmacology_count(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_info(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_info_batch(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_pharmacology(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_pharmacology_count(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.smiles_to_url(VALID_SMILES)}.to raise_error OPS::ForbiddenError
        expect {@client.exact_structure_search(VALID_SMILES)}.to raise_error OPS::ForbiddenError
        expect {@client.similarity_search(VALID_SMILES)}.to raise_error OPS::ForbiddenError
        expect {@client.substructure_search(VALID_SMILES)}.to raise_error OPS::ForbiddenError
      end
    end
  end



  describe '#compound_info' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the compound is unknown to OPS' do
        expect {@client.compound_info(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the compound uri is invalid' do
        expect {@client.compound_info(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:status => 500)
        expect {@client.compound_info(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {@client.compound_info}.to raise_error(ArgumentError)
      end

      it "returns the compound info if the compound is known to OPS" do
        @client.compound_info(VALID_COMPOUND_URI).should == {
          :"http://ops.rsc.org"=>{
            :uri=>"http://ops.rsc.org/OPS3",
            :hba=>9, :hbd=>6,
            :inchi=>"InChI=1S/C21H24O9/c1-28-16-5-4-11(8-15(16)24)2-3-12-6-13(23)9-14(7-12)29-21-20(27)19(26)18(25)17(10-22)30-21/h2-9,17-27H,10H2,1H3/b3-2+",
            :inchikey=>"GKAJCVFOJGXVIA-NSCUHMNNSA-N",
            :logp=>0.684, :molformula=>"C21H24O9",
            :molweight=>420.41, :psa=>149.07,
            :ro5_violations=>1, :rtb=>12,
            :smiles=>"COC1=C(C=C(C=C1)/C=C/C2=CC(=CC(=C2)OC3C(C(C(C(O3)CO)O)O)O)O)O"
          },
          :"http://www.ebi.ac.uk/chembl"=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1987358",
            :mw_freebase=>420.41,
            :type=>"http://rdf.ebi.ac.uk/terms/chembl#SmallMolecule"
          },
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/a371d2ba-4c32-4fad-99dc-3b1d5357d29d",
            :pref_label_en=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside",
            :pref_label=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside"
          }
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.compound_info(VALID_COMPOUND_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.compound_info(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#compound_info_batch' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the compound is unknown to OPS' do
        expect {@client.compound_info_batch(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the compound uri is invalid' do
        expect {@client.compound_info_batch(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:post, "#{OPS_SETTINGS[:url]}/compound/batch").to_return(:status => 500)
        expect {@client.compound_info_batch(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {@client.compound_info_batch}.to raise_error(ArgumentError)
      end

      it "returns the compound info if the compound is known to OPS" do
        @client.compound_info_batch(VALID_COMPOUND_URI).should == {
          :uri=>"https://beta.openphacts.org/1.4/compound/batch",
          :modified=>"Tuesday, 14-Oct-14 09:52:21 UTC",
          :definition=>"https://beta.openphacts.org/api-config",
          :extended_metadata_version=>"https://beta.openphacts.org/1.4/compound/batch?_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite",
          :type=>"http://purl.org/linked-data/api/vocab#List",
          :items=>[
            {
              :"http://ops.rsc.org"=>{
                :uri=>"http://ops.rsc.org/OPS3", :hba=>9, :hbd=>6,
                :inchi=>"InChI=1S/C21H24O9/c1-28-16-5-4-11(8-15(16)24)2-3-12-6-13(23)9-14(7-12)29-21-20(27)19(26)18(25)17(10-22)30-21/h2-9,17-27H,10H2,1H3/b3-2+",
                :inchikey=>"GKAJCVFOJGXVIA-NSCUHMNNSA-N", :logp=>0.684, :molformula=>"C21H24O9",
                :molweight=>420.41, :psa=>149.07, :ro5_violations=>1, :rtb=>12,
                :smiles=>"COC1=C(C=C(C=C1)/C=C/C2=CC(=CC(=C2)OC3C(C(C(C(O3)CO)O)O)O)O)O",
                :same_as=>["http://ops.rsc.org/OPS3", "http://ops.rsc.org/OPS3/rdf"]
              },
              :"http://www.ebi.ac.uk/chembl"=>{
                :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1987358",
                :mw_freebase=>420.41, :type=>"http://rdf.ebi.ac.uk/terms/chembl#SmallMolecule"
              },
              :"http://www.conceptwiki.org"=>{
                :uri=>"http://www.conceptwiki.org/concept/a371d2ba-4c32-4fad-99dc-3b1d5357d29d",
                :pref_label_en=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside",
                :pref_label=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside"
              }
            }
          ]
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.compound_info_batch(VALID_COMPOUND_URI).should_not be_nil
      end

      it "works with both '|' delimited string and array of uris" do
        uriList = [VALID_COMPOUND_URI, VALID_COMPOUND_URI]
        expect(@client.compound_info_batch(uriList)).to eq(@client.compound_info_batch(uriList.join("|")))
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:post, "#{OPS_SETTINGS[:url]}/compound/batch").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.compound_info_batch(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#compound_pharmacology' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the compound is unknown to OPS' do
        expect {@client.compound_pharmacology(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the compound uri is invalid' do
        expect {@client.compound_pharmacology(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound/pharmacology/pages?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}&_pageSize=all").
          to_return(:status => 500)
        expect {@client.compound_pharmacology(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {@client.compound_pharmacology}.to raise_error(ArgumentError)
      end

      it "returns the compound pharmacology if the compound is known to OPS" do
        result = @client.compound_pharmacology(VALID_COMPOUND_URI)
        result[:items].count.should == 59
        result[:items].first.should == {
          :uri=>"http://rdf.ebi.ac.uk/resource/chembl/activity/CHEMBL_ACT_10006980",
          :activity_comment=>"inactive",
          :has_assay=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/assay/CHEMBL1963885",
            :description=>"PUBCHEM_BIOASSAY: NCI human tumor cell line growth inhibition assay. Data for the PC-3 Prostate cell line.   (Class of assay: confirmatory) ",
            :has_target=>{
              :uri=>"http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL390",
              :title=>"PC-3",
              :target_organism_name=>"Homo sapiens",
              :type=>"http://rdf.ebi.ac.uk/terms/chembl#CellLine"
            }
          },
          :has_molecule=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1987358",
            :"http://ops.rsc.org"=>{
              :uri=>"http://ops.rsc.org/OPS3",
              :inchi=>"InChI=1S/C21H24O9/c1-28-16-5-4-11(8-15(16)24)2-3-12-6-13(23)9-14(7-12)29-21-20(27)19(26)18(25)17(10-22)30-21/h2-9,17-27H,10H2,1H3/b3-2+",
              :inchikey=>"GKAJCVFOJGXVIA-NSCUHMNNSA-N",
              :molweight=>420.41,
              :ro5_violations=>1,
              :smiles=>"COC1=C(C=C(C=C1)/C=C/C2=CC(=CC(=C2)OC3C(C(C(C(O3)CO)O)O)O)O)O"
            },
            :"http://www.conceptwiki.org"=>{
              :uri=>"http://www.conceptwiki.org/concept/a371d2ba-4c32-4fad-99dc-3b1d5357d29d",
              :pref_label_en=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside",
              :pref_label=>"3-Hydroxy-5-[(E)-2-(3-hydroxy-4-methoxyphenyl)vinyl]phenyl hexopyranoside"
            }
          },
          :activity_unit=>{
            :uri=>"http://www.openphacts.org/units/Nanomolar",
            :pref_label=>"nM"
          },
          :published_type=>"log GI50 (M)",
          :published_value=>-4.308,
          :activity_type=>"GI50",
          :activity_value=>49203.95
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.compound_pharmacology(VALID_COMPOUND_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound/pharmacology/pages?_pageSize=all&_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.compound_pharmacology(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#compound_pharmacology_count' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'does not raise an error if the compound is unknown to OPS' do
        expect {@client.compound_pharmacology_count(UNKNOWN_URI)}.to_not raise_error
      end

      it 'returns count=0 if the compound is unknown to OPS' do
        @client.compound_pharmacology_count(UNKNOWN_URI).should == {:uri => UNKNOWN_URI, :count => 0}
      end

      it 'raises BadRequestError if the compound uri is invalid' do
        expect {@client.compound_pharmacology_count(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound/pharmacology/count?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:status => 500)
        expect {@client.compound_pharmacology_count(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {@client.compound_pharmacology_count}.to raise_error(ArgumentError)
      end

      it "returns the compound pharmacology count if the compound is known to OPS" do
        @client.compound_pharmacology_count(VALID_COMPOUND_URI).should == {:uri => VALID_COMPOUND_URI, :count => 59}
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.compound_pharmacology_count(VALID_COMPOUND_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/compound/pharmacology/count?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.compound_pharmacology_count(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#target_info' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the target is unknown to OPS' do
        expect {@client.target_info(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the target uri is invalid' do
        expect {@client.target_info(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:status => 500)
        expect {@client.target_info(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no target URI is given" do
        expect {@client.target_info}.to raise_error(ArgumentError)
      end

      it "returns the target info if the target is known to OPS" do
        @client.target_info(VALID_TARGET_URI).should == {
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291",
            :pref_label_en=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)",
            :pref_label=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)"
          },
          :"http://linkedlifedata.com/resource/drugbank"=>{
            :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198",
            :target_for_drug=>[
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00807",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Proparacaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00297",
                :drug_type=>["approved", "smallMolecule", "investigational"], :generic_name=>"Bupivacaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00296",
                :drug_type=>["approved", "smallMolecule"], :generic_name=>"Ropivacaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01161",
                :drug_type=>["approved", "smallMolecule"], :generic_name=>"Chloroprocaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00281",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Lidocaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00892",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Oxybuprocaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00527",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Dibucaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00907",
                :drug_type=>["approved", "smallMolecule", "illicit"], :generic_name=>"Cocaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00645",
                :drug_type=>["approved", "smallMolecule"], :generic_name=>"Dyclonine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01002",
                :drug_type=>["approved", "smallMolecule"], :generic_name=>"Levobupivacaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01086",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Benzocaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00961",
                :drug_type=>["smallMolecule", "approved"], :generic_name=>"Mepivacaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00473",
                :drug_type=>["approved", "smallMolecule"], :generic_name=>"Hexylcaine"
              },
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00721",
                :drug_type=>["approved", "smallMolecule", "investigational"], :generic_name=>"Procaine"
              }
            ],
            :cellular_location=>["multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough", "membrane"],
            :number_of_residues=>"1988", :theoretical_pi=>"5.77"
          },
          :"http://purl.uniprot.org"=>{
            :uri=>"http://purl.uniprot.org/uniprot/Q9Y5Y9",
            :function_annotation=>"This protein mediates the voltage-dependent sodium ion permeability of excitable membranes. Assuming opened or closed conformations in response to the voltage difference across the membrane, the protein forms a sodium-selective channel through which sodium ions may pass in accordance with their electrochemical gradient. It is a tetrodotoxin-resistant sodium channel isoform. Its electrophysiological properties vary depending on the type of the associated beta subunits (in vitro). Plays a role in neuropathic pain mechanisms (By similarity).",
            :alternative_name=>["Voltage-gated sodium channel subunit alpha Nav1.8", "Peripheral nerve sodium channel 3", "Sodium channel protein type X subunit alpha"],
            :classified_with=>["http://purl.uniprot.org/keywords/1185", "http://purl.uniprot.org/go/0001518", "http://purl.uniprot.org/keywords/1133", "http://purl.uniprot.org/go/0055117", "http://purl.uniprot.org/go/0019233", "http://purl.uniprot.org/go/0005248", "http://purl.uniprot.org/go/0042475", "http://purl.uniprot.org/go/0007600", "http://purl.uniprot.org/keywords/325", "http://purl.uniprot.org/keywords/851", "http://purl.uniprot.org/go/0071439", "http://purl.uniprot.org/keywords/677", "http://purl.uniprot.org/go/0060371", "http://purl.uniprot.org/keywords/621", "http://purl.uniprot.org/keywords/894", "http://purl.uniprot.org/go/0002027", "http://purl.uniprot.org/keywords/832", "http://purl.uniprot.org/go/0086067", "http://purl.uniprot.org/go/0086069"],
            :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence",
            :organism=>"http://purl.uniprot.org/taxonomy/9606"
          },
          :"http://www.ebi.ac.uk/chembl"=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL5451",
            :has_target_component=>{
              :uri=>"http://rdf.ebi.ac.uk/resource/chembl/targetcomponent/CHEMBL_TC_3744",
              :description=>"Sodium channel protein type 10 subunit alpha"
            },
            :type=>"http://rdf.ebi.ac.uk/terms/chembl#SingleProtein",
            :label=>"Sodium channel protein type X alpha subunit"
          }
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.target_info(VALID_TARGET_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.target_info(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#target_info_batch' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the target is unknown to OPS' do
        expect {@client.target_info_batch(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the target uri is invalid' do
        expect {@client.target_info_batch(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:post, "#{OPS_SETTINGS[:url]}/target/batch").to_return(:status => 500)
        expect {@client.target_info_batch(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no target URI is given" do
        expect {@client.target_info_batch}.to raise_error(ArgumentError)
      end

      it "returns the target info if the target is known to OPS" do
        @client.target_info_batch(VALID_TARGET_URI).should == {
          :uri=>"https://beta.openphacts.org/1.4/target/batch",
          :modified=>"Tuesday, 14-Oct-14 09:52:25 UTC",
          :definition=>"https://beta.openphacts.org/api-config",
          :extended_metadata_version=>"https://beta.openphacts.org/1.4/target/batch?_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite",
          :type=>"http://purl.org/linked-data/api/vocab#List",
          :items=>[
            {
              :"http://www.conceptwiki.org"=>{
                :uri=>"http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291",
                :same_as=>["http://www.conceptwiki.org/concept/index/00059958-a045-4581-9dc5-e5a08bb0c291", "http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291"],
                :mapping_relation=>{
                  :uri=>"http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL5451",
                  :has_target_component=>{
                    :uri=>"http://rdf.ebi.ac.uk/resource/chembl/targetcomponent/CHEMBL_TC_3744",
                    :description=>"Sodium channel protein type 10 subunit alpha"
                  },
                  :type=>"http://rdf.ebi.ac.uk/terms/chembl#SingleProtein",
                  :label=>"Sodium channel protein type X alpha subunit"
                },
                :pref_label_en=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)",
                :pref_label=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)"
              },
              :"http://purl.uniprot.org"=>{
                :uri=>"http://purl.uniprot.org/uniprot/Q9Y5Y9",
                :function_annotation=>"This protein mediates the voltage-dependent sodium ion permeability of excitable membranes. Assuming opened or closed conformations in response to the voltage difference across the membrane, the protein forms a sodium-selective channel through which sodium ions may pass in accordance with their electrochemical gradient. It is a tetrodotoxin-resistant sodium channel isoform. Its electrophysiological properties vary depending on the type of the associated beta subunits (in vitro). Plays a role in neuropathic pain mechanisms (By similarity).",
                :alternative_name=>["Voltage-gated sodium channel subunit alpha Nav1.8", "Peripheral nerve sodium channel 3", "Sodium channel protein type X subunit alpha"],
                :classified_with=>["http://purl.uniprot.org/keywords/1185", "http://purl.uniprot.org/go/0001518", "http://purl.uniprot.org/keywords/1133", "http://purl.uniprot.org/go/0055117", "http://purl.uniprot.org/go/0019233", "http://purl.uniprot.org/go/0005248", "http://purl.uniprot.org/go/0042475", "http://purl.uniprot.org/go/0007600", "http://purl.uniprot.org/keywords/325", "http://purl.uniprot.org/keywords/851", "http://purl.uniprot.org/go/0071439", "http://purl.uniprot.org/keywords/677", "http://purl.uniprot.org/go/0060371", "http://purl.uniprot.org/keywords/621", "http://purl.uniprot.org/keywords/894", "http://purl.uniprot.org/go/0002027", "http://purl.uniprot.org/keywords/832", "http://purl.uniprot.org/go/0086067", "http://purl.uniprot.org/go/0086069"],
                :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence",
                :organism=>"http://purl.uniprot.org/taxonomy/9606"
              },
              :"http://linkedlifedata.com/resource/drugbank"=>{
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198",
                :target_for_drug=>[
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00807",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Proparacaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00297",
                    :drug_type=>["approved", "smallMolecule", "investigational"],
                    :generic_name=>"Bupivacaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00296",
                    :drug_type=>["approved", "smallMolecule"], :generic_name=>"Ropivacaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01161",
                    :drug_type=>["approved", "smallMolecule"], :generic_name=>"Chloroprocaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00281",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Lidocaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00892",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Oxybuprocaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00527",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Dibucaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00907",
                    :drug_type=>["approved", "smallMolecule", "illicit"], :generic_name=>"Cocaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00645",
                    :drug_type=>["approved", "smallMolecule"], :generic_name=>"Dyclonine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01002",
                    :drug_type=>["approved", "smallMolecule"], :generic_name=>"Levobupivacaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB01086",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Benzocaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00961",
                    :drug_type=>["smallMolecule", "approved"], :generic_name=>"Mepivacaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00473",
                    :drug_type=>["approved", "smallMolecule"], :generic_name=>"Hexylcaine"
                  },
                  {
                    :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00721",
                    :drug_type=>["approved", "smallMolecule", "investigational"],
                    :generic_name=>"Procaine"
                  }
                ],
                :cellular_location=>["multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough", "membrane"],
                :number_of_residues=>"1988", :theoretical_pi=>"5.77"
              }
            }
          ]
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.target_info_batch(VALID_TARGET_URI).should_not be_nil
      end

      it "works with both '|' delimited string and array of uris" do
        uriList = [VALID_TARGET_URI, VALID_TARGET_URI]
        expect(@client.target_info_batch(uriList)).to eq(@client.target_info_batch(uriList.join("|")))
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:post, "#{OPS_SETTINGS[:url]}/target/batch").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.target_info_batch(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#target_pharmacology' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the target is unknown to OPS' do
        expect {@client.target_pharmacology(UNKNOWN_URI)}.to raise_error OPS::NotFoundError
      end

      it 'raises BadRequestError if the target uri is invalid' do
        expect {@client.target_pharmacology(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target/pharmacology/pages?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}&_pageSize=all").
          to_return(:status => 500)
        expect {@client.target_pharmacology(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no target URI is given" do
        expect {@client.target_pharmacology}.to raise_error(ArgumentError)
      end

      it "returns the target info if the target is known to OPS" do
        result = @client.target_pharmacology(VALID_TARGET_URI)
        result[:items].count.should == 168


        result[:items].first.should == {
          :uri=>"http://rdf.ebi.ac.uk/resource/chembl/activity/CHEMBL_ACT_1985117",
          :pmid=>"http://identifiers.org/pubmed/17804230",
          :has_assay=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/assay/CHEMBL899665",
            :description=>"Inhibition of sodium channel NaV1.8 at 20 ug/mL by HTS assay",
            :assay_organism_name=>"Homo sapiens",
            :has_target=>{
              :uri=>"http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL5451",
              :title=>"Sodium channel protein type X alpha subunit",
              :has_target_component=>{
                :uri=>"http://rdf.ebi.ac.uk/resource/chembl/targetcomponent/CHEMBL_TC_3744",
                :"http://www.conceptwiki.org"=>{
                  :uri=>"http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291",
                  :pref_label_en=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)",
                  :pref_label=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)"
                }
              },
              :target_organism_name=>"Homo sapiens",
              :type=>"http://rdf.ebi.ac.uk/terms/chembl#SingleProtein"
            }
          },
          :has_molecule=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1162028",
            :"http://www.conceptwiki.org"=>{
              :uri=>"http://www.conceptwiki.org/concept/f306f83a-132a-4bba-9914-a3cbd191d552",
              :pref_label_en=>"[(3S,5S,6S,8S,10S,13S,14S,17S)-6-[(2R,3R,4S,5R,6R)-3,5-dihydroxy-4-[(2S,3R,4S,5R)-4-hydroxy-5-[(2S,3R,4S,5S,6R)-4-hydroxy-6-methyl-3-[(2S,3R,4S,5R,6R)-3,4,5-trihydroxy-6-methyl-tetrahydropyran-2-yl]oxy-5-[(2S,3R,4S,5S)-3,4,5-trihydroxytetrahydropyran-2-yl]oxy-tetrahydropyran-2-yl]oxy-3-[(2S,3R,4S,5S,6R)-3,4,5-trihydroxy-6-methyl-tetrahydropyran-2-yl]oxy-tetrahydropyran-2-yl]oxy-6-methyl-tetrahydropyran-2-yl]oxy-17-[(1R)-1-hydroxy-1,5-dimethyl-hexyl]-10,13-dimethyl-2,3,4,5,6,7,8,12,14,15,16,17-dodecahydro-1H-cyclopenta[a]phenanthren-3-yl] hydrogen sulfate",
              :pref_label=>"[(3S,5S,6S,8S,10S,13S,14S,17S)-6-[(2R,3R,4S,5R,6R)-3,5-dihydroxy-4-[(2S,3R,4S,5R)-4-hydroxy-5-[(2S,3R,4S,5S,6R)-4-hydroxy-6-methyl-3-[(2S,3R,4S,5R,6R)-3,4,5-trihydroxy-6-methyl-tetrahydropyran-2-yl]oxy-5-[(2S,3R,4S,5S)-3,4,5-trihydroxytetrahydropyran-2-yl]oxy-tetrahydropyran-2-yl]oxy-3-[(2S,3R,4S,5S,6R)-3,4,5-trihydroxy-6-methyl-tetrahydropyran-2-yl]oxy-tetrahydropyran-2-yl]oxy-6-methyl-tetrahydropyran-2-yl]oxy-17-[(1R)-1-hydroxy-1,5-dimethyl-hexyl]-10,13-dimethyl-2,3,4,5,6,7,8,12,14,15,16,17-dodecahydro-1H-cyclopenta[a]phenanthren-3-yl] hydrogen sulfate"
            },
            :"http://ops.rsc.org"=>{
              :uri=>"http://ops.rsc.org/OPS1340718",
              :inchi=>"InChI=1S/C61H102O30S/c1-23(2)11-10-16-61(9,75)36-13-12-30-29-20-34(32-19-28(91-92(76,77)78)14-17-59(32,7)31(29)15-18-60(30,36)8)85-56-48(74)50(39(65)26(5)83-56)88-57-51(89-54-45(71)42(68)37(63)24(3)81-54)41(67)35(22-80-57)86-58-52(90-55-46(72)43(69)38(64)25(4)82-55)47(73)49(27(6)84-58)87-53-44(70)40(66)33(62)21-79-53/h15,23-30,32-58,62-75H,10-14,16-22H2,1-9H3,(H,76,77,78)/t24-,25-,26-,27-,28+,29+,30+,32-,33+,34+,35-,36+,37-,38+,39-,40+,41+,42+,43+,44-,45-,46-,47+,48-,49-,50+,51-,52-,53+,54+,55+,56+,57+,58+,59-,60+,61-/m1/s1",
              :inchikey=>"YGJYYDTWXBCDRA-MIRNQWDESA-N",
              :molweight=>1347.51,
              :ro5_violations=>4,
              :smiles=>"C[C@@H]1[C@H]([C@@H]([C@H]([C@@H](O1)O[C@@H]2[C@H]([C@@H](CO[C@H]2O[C@H]3[C@@H]([C@H](O[C@H]([C@@H]3O)O[C@H]4C[C@H]5[C@@H]6CC[C@@H]([C@]6(CC=C5[C@@]7([C@@H]4C[C@H](CC7)OS(=O)(=O)O)C)C)[C@@](C)(CCCC(C)C)O)C)O)O[C@H]8[C@@H]([C@H]([C@@H]([C@H](O8)C)O[C@H]9[C@@H]([C@H]([C@H](CO9)O)O)O)O)O[C@H]1[C@@H]([C@H]([C@H]([C@H](O1)C)O)O)O)O)O)O)O"
            }
          },
          :activity_unit=>{
            :uri=>"http://qudt.org/vocab/unit#Percent",
            :pref_label=>"%"
          },
          :published_relation=>"=",
          :published_type=>"Inhibition",
          :published_units=>"%",
          :published_value=>88,
          :activity_relation=>"=",
          :activity_type=>"Inhibition",
          :activity_value=>88
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.target_pharmacology(VALID_TARGET_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target/pharmacology/pages?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}&_pageSize=all").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.target_pharmacology(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#target_pharmacology_count' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises no error if the target is unknown to OPS' do
        expect {@client.target_pharmacology_count(UNKNOWN_URI)}.to_not raise_error
      end

      it 'returns count=0 if the target is unknown to OPS' do
        @client.target_pharmacology_count(UNKNOWN_URI).should == {:uri=>UNKNOWN_URI, :count=>0}
      end

      it 'raises BadRequestError if the target uri is invalid' do
        expect {@client.target_pharmacology_count(INVALID_URI)}.to raise_error OPS::BadRequestError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target/pharmacology/count?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:status => 500)
        expect {@client.target_pharmacology_count(UNKNOWN_URI)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no target URI is given" do
        expect {@client.target_pharmacology_count}.to raise_error(ArgumentError)
      end

      it "returns the target info if the target is known to OPS" do
        @client.target_pharmacology_count(VALID_TARGET_URI).should == {:uri=>VALID_TARGET_URI, :count=>168}
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.target_pharmacology_count(VALID_TARGET_URI).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/target/pharmacology/count?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&uri=#{UNKNOWN_URI}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.target_pharmacology_count(UNKNOWN_URI)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end



  describe '#smiles_to_url' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises InternalServerError if the smiles is unknown to OPS' do
        expect {@client.smiles_to_url(UNKNOWN_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.smiles_to_url(INVALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&smiles=#{VALID_SMILES}").
          to_return(:status => 500)
        expect {@client.smiles_to_url(VALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no smiles URI is given" do
        expect {@client.smiles_to_url}.to raise_error(ArgumentError)
      end

      it "returns the URI if the smiles is known to OPS" do
        @client.smiles_to_url(VALID_SMILES).should == {:smiles=>VALID_SMILES, :uri=>'http://ops.rsc.org/OPS2157'}
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.smiles_to_url(VALID_SMILES).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&smiles=#{VALID_SMILES}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.smiles_to_url(VALID_SMILES)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end

  describe '#exact_structure_search' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises OPS::NotFoundError if the smiles is unknown to OPS' do
        expect {@client.exact_structure_search(UNKNOWN_SMILES)}.to raise_error OPS::NotFoundError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.exact_structure_search(INVALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/exact?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:status => 500)

        expect {@client.exact_structure_search(VALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no smiles URI is given" do
        expect {@client.exact_structure_search}.to raise_error(ArgumentError)
      end

      it "returns results if the smiles is known to OPS" do
        @client.exact_structure_search(VALID_SMILES).should == {
          :uri=>"http://www.openphacts.org/api/ChemicalStructureSearch",
          :result=>"http://ops.rsc.org/OPS403534",
          :molecule=>"CC(=O)Oc1ccccc1C(=O)O",
          :type=>"http://www.openphacts.org/api/ExactStructureSearch"
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.exact_structure_search(VALID_SMILES).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/exact?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.exact_structure_search(VALID_SMILES)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end

  describe '#similarity_search' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises OPS::NotFoundError if the smiles is unknown to OPS' do
        expect {@client.similarity_search(UNKNOWN_SMILES, 'resultOptions.Count' => 5, 'searchOptions.Threshold' => 0.9)}.to raise_error OPS::NotFoundError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.similarity_search(INVALID_SMILES, 'resultOptions.Count' => 5, 'searchOptions.Threshold' => 0.9)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/similarity?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:status => 500)

        expect {@client.similarity_search(VALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no smiles URI is given" do
        expect {@client.similarity_search}.to raise_error(ArgumentError)
      end

      it "returns results if the smiles is known to OPS" do
        @client.similarity_search(VALID_SMILES, 'resultOptions.Count' => 5, 'searchOptions.Threshold' => 0.9).should == {
          :uri=>"http://www.openphacts.org/api/ChemicalStructureSearch",
          :result=>[
            {:uri=>"http://ops.rsc.org/OPS403534", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS666650", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS1056157", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS684682", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS767417", :relevance=>0.97727274894714}
          ],
          :count=>"5", :molecule=>"CC(=O)Oc1ccccc1C(=O)O", :threshold=>"0.9",
          :type=>"http://www.openphacts.org/api/SimilaritySearch"
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.similarity_search(VALID_SMILES, 'resultOptions.Count' => 5, 'searchOptions.Threshold' => 0.9).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/similarity?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.similarity_search(VALID_SMILES)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end

  describe '#substructure_search' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises NotFoundError if the smiles is unknown to OPS' do
        expect {@client.substructure_search(UNKNOWN_SMILES)}.to raise_error OPS::NotFoundError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.substructure_search(INVALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/substructure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}&searchOptions.MolType=0").
          to_return(:status => 500)
        expect {@client.substructure_search(VALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no smiles URI is given" do
        expect {@client.substructure_search}.to raise_error(ArgumentError)
      end

      it "returns results if the smiles is known to OPS" do
        @client.substructure_search(VALID_SMILES, 'resultOptions.Count' => 5).should == {
          :uri=>"http://www.openphacts.org/api/ChemicalStructureSearch",
          :result=>[
            {:uri=>"http://ops.rsc.org/OPS403534", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS666650", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS1056157", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS684682", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS1522274", :relevance=>0.97727274894714}
          ],
          :count=>"5", :mol_type=>"0", :molecule=>"CC(=O)Oc1ccccc1C(=O)O",
          :type=>"http://www.openphacts.org/api/SubstructureSearch"
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.substructure_search(VALID_SMILES, 'resultOptions.Count' => 5).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/substructure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}&searchOptions.MolType=0").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.substructure_search(VALID_SMILES)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end


end
