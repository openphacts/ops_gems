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
  :url => 'https://beta.openphacts.org/1.3',
  :app_id => 'secret_id',
  :app_key => 'secret_key'
}.freeze

VALID_COMPOUND_URI  = 'http://ops.rsc.org/OPS3'
VALID_TARGET_URI    = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
INVALID_URI         = '#187440'
UNKNOWN_URI         = 'http://unknown.com/1111'
VALID_SMILES        = 'CC(=O)Oc1ccccc1C(=O)O'
INVALID_SMILES      = 'CCC)'
UNKNOWN_SMILES      = 'C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=CC=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C=C'


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
        expect {@client.compound_pharmacology(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.compound_pharmacology_count(VALID_COMPOUND_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_info(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_pharmacology(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.target_pharmacology_count(VALID_TARGET_URI)}.to raise_error OPS::ForbiddenError
        expect {@client.smiles_to_url(VALID_SMILES)}.to raise_error OPS::ForbiddenError
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
            :hba=>5, :hbd=>1,
            :inchi=>"InChI=1S/C18H18Cl2N4O/c1-23-7-5-18(6-8-23)11(9-21)13-10-3-4-12(19)14(20)15(10)24(2)16(13)17(25)22-18/h3-4,11H,5-8H2,1-2H3,(H,22,25)",
            :inchikey=>"XGUIMGJMQKZRGM-UHFFFAOYSA-N",
            :logp=>2.044, :molformula=>"C18H18Cl2N4O",
            :molweight=>377.268, :psa=>61.06,
            :ro5_violations=>0, :rtb=>0,
            :smiles=>"CN1CCC2(CC1)C(C3=C(C(=O)N2)N(C4=C3C=CC(=C4Cl)Cl)C)C#N"
          },
          :"http://www.ebi.ac.uk/chembl"=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1945556",
            :mw_freebase=>377.27,
            :type=>"http://rdf.ebi.ac.uk/terms/chembl#SmallMolecule"
          },
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/3ab638be-f601-4ad7-875f-c954ad76a826",
            :pref_label_en=>"7,8-Dichloro-1',9-dimethyl-1-oxo-1,2,4,9-tetrahydrospiro[beta-carboline-3,4'-piperidine]-4-carbonitrile",
            :pref_label=>"7,8-Dichloro-1',9-dimethyl-1-oxo-1,2,4,9-tetrahydrospiro[beta-carboline-3,4'-piperidine]-4-carbonitrile"
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
        result[:items].count.should == 28
        result[:items].first.should == {
          :uri=>"http://rdf.ebi.ac.uk/resource/chembl/activity/CHEMBL_ACT_8013130",
          :pmid=>"http://identifiers.org/pubmed/22136433",
          :activity_comment=>"Not Active",
          :has_assay=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/assay/CHEMBL1948137",
            :description=>"Inhibition of PDGFRalpha using ATP as substrate",
            :has_target=>{
              :uri=>"http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL2007",
              :title=>"Platelet-derived growth factor receptor alpha ",
              :has_target_component=>{
                :uri=>"http://rdf.ebi.ac.uk/resource/chembl/targetcomponent/CHEMBL_TC_338"
              },
              :target_organism_name=>"Homo sapiens",
              :type=>"http://rdf.ebi.ac.uk/terms/chembl#SingleProtein"
            }
          },
          :has_molecule=>{
            :"http://www.ebi.ac.uk/chembl"=>{
              :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1945556"
            },
            :"http://ops.rsc.org"=>{
              :uri=>"http://ops.rsc.org/OPS3",
              :inchi=>"InChI=1S/C18H18Cl2N4O/c1-23-7-5-18(6-8-23)11(9-21)13-10-3-4-12(19)14(20)15(10)24(2)16(13)17(25)22-18/h3-4,11H,5-8H2,1-2H3,(H,22,25)",
              :inchikey=>"XGUIMGJMQKZRGM-UHFFFAOYSA-N",
              :molweight=>377.268, :ro5_violations=>0,
              :smiles=>"CN1CCC2(CC1)C(C3=C(C(=O)N2)N(C4=C3C=CC(=C4Cl)Cl)C)C#N"
            },
            :"http://www.conceptwiki.org"=>{
              :uri=>"http://www.conceptwiki.org/concept/3ab638be-f601-4ad7-875f-c954ad76a826",
              :pref_label_en=>"7,8-Dichloro-1',9-dimethyl-1-oxo-1,2,4,9-tetrahydrospiro[beta-carboline-3,4'-piperidine]-4-carbonitrile",
              :pref_label=>"7,8-Dichloro-1',9-dimethyl-1-oxo-1,2,4,9-tetrahydrospiro[beta-carboline-3,4'-piperidine]-4-carbonitrile"
            }
          },
          :published_type=>"INH",
          :activity_type=>"Inhibition"
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
        @client.compound_pharmacology_count(VALID_COMPOUND_URI).should == {:uri => VALID_COMPOUND_URI, :count => 28}
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
          :"http://purl.uniprot.org"=>{
            :uri=>"http://purl.uniprot.org/uniprot/Q9Y5Y9",
            :function_annotation=>"This protein mediates the voltage-dependent sodium ion permeability of excitable membranes. Assuming opened or closed conformations in response to the voltage difference across the membrane, the protein forms a sodium-selective channel through which sodium ions may pass in accordance with their electrochemical gradient. It is a tetrodotoxin-resistant sodium channel isoform. Its electrophysiological properties vary depending on the type of the associated beta subunits (in vitro). Plays a role in neuropathic pain mechanisms (By similarity).",
            :alternative_name=>["Peripheral nerve sodium channel 3", "Voltage-gated sodium channel subunit alpha Nav1.8", "Sodium channel protein type X subunit alpha"],
            :classified_with=>["http://purl.uniprot.org/keywords/677", "http://purl.uniprot.org/keywords/832", "http://purl.uniprot.org/go/0071439", "http://purl.uniprot.org/keywords/894", "http://purl.uniprot.org/keywords/1133", "http://purl.uniprot.org/keywords/1185", "http://purl.uniprot.org/go/0002027", "http://purl.uniprot.org/go/0086067", "http://purl.uniprot.org/go/0086069", "http://purl.uniprot.org/keywords/325", "http://purl.uniprot.org/go/0019233", "http://purl.uniprot.org/go/0042475", "http://purl.uniprot.org/go/0060371", "http://purl.uniprot.org/keywords/851", "http://purl.uniprot.org/keywords/621", "http://purl.uniprot.org/go/0001518", "http://purl.uniprot.org/go/0005248", "http://purl.uniprot.org/go/0055117", "http://purl.uniprot.org/go/0007600"],
            :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence",
            :organism=>"http://purl.uniprot.org/taxonomy/9606"
          },
          :"http://linkedlifedata.com/resource/drugbank"=>{
            :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198",
            :cellular_location=>["membrane", "multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough"],
            :number_of_residues=>"1988",
            :theoretical_pi=>"5.77"
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
                :uri=>"http://rdf.ebi.ac.uk/resource/chembl/targetcomponent/CHEMBL_TC_3744"
              },
              :target_organism_name=>"Homo sapiens",
              :type=>"http://rdf.ebi.ac.uk/terms/chembl#SingleProtein"
            }
          },
          :has_molecule=>{
            :uri=>"http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL1162028"
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
        @client.smiles_to_url(VALID_SMILES).should == {:smiles=>VALID_SMILES, :uri=>'http://ops.rsc.org/OPS2954'}
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

  describe '#similarity_search' do
    context 'with correct settings' do
      before :each do
        @client = OPS::OpenPhactsClient.new(OPS_SETTINGS)
      end

      it 'raises InternalServerError if the smiles is unknown to OPS' do
        expect {@client.similarity_search(UNKNOWN_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.similarity_search(INVALID_SMILES)}.to raise_error OPS::InternalServerError
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
            {:uri=>"http://ops.rsc.org/OPS2954", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS28298", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS4291", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS18084", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS324814", :relevance=>0.97727274894714}
          ],
          :count=>"5", :molecule=>VALID_SMILES, :threshold=>"0.9",
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

      it 'raises InternalServerError if the smiles is unknown to OPS' do
        expect {@client.substructure_search(UNKNOWN_SMILES)}.to raise_error OPS::InternalServerError
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
            {:uri=>"http://ops.rsc.org/OPS2954", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS28298", :relevance=>1},
            {:uri=>"http://ops.rsc.org/OPS4291", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS324814", :relevance=>0.97727274894714},
            {:uri=>"http://ops.rsc.org/OPS330642", :relevance=>0.97727274894714}
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
