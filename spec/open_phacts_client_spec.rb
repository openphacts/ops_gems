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
  :url => 'https://beta.openphacts.org',
  :app_id => 'secret_id',
  :app_key => 'secret_key'
}.freeze

VALID_COMPOUND_URI  = 'http://rdf.chemspider.com/3'
VALID_TARGET_URI    = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
INVALID_URI         = '#187440'
UNKNOWN_URI         = 'http://unknown.com/1111'
VALID_SMILES        = 'CCCC'
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
          :"http://www.chemspider.com"=>{
            :uri=>"http://rdf.chemspider.com/3",
            :inchi=>"InChI=1S/C3H9NO/c1-3(5)2-4/h3,5H,2,4H2,1H3",
            :inchikey=>"HXKKHQJGJAFBHI-UHFFFAOYSA-N",
            :smiles=>"OC(C)CN",
            :hba=>2, :hbd=>3, :logp=>-1.127,
            :psa=>4.6250000000000004e-18, :ro5_violations=>0
          },
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/c99deece-3cd6-49c7-991f-b0efb51ddc80",
            :pref_label_en=>"1-Aminopropan-2-ol",
            :pref_label=>"1-Aminopropan-2-ol"
          },
          :"http://data.kasabi.com/dataset/chembl-rdf"=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL326602",
            :full_mwt=>75.1096, :molform=>"C3H9NO", :mw_freebase=>75.1096, :rtb=>1
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
        result[:items].count.should == 2
        result[:items].first.should == {
          :uri=>"http://data.kasabi.com/dataset/chembl-rdf/activity/a1082946",
          :pmid=>"9357523",
          :for_molecule=>{
            :"http://data.kasabi.com/dataset/chembl-rdf"=>{
              :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL326602",
              :full_mwt=>75.1096
            },
            :"http://www.conceptwiki.org/"=>{
              :uri=>"http://www.conceptwiki.org/concept/c99deece-3cd6-49c7-991f-b0efb51ddc80",
              :pref_label_en=>"1-Aminopropan-2-ol",
              :pref_label=>"1-Aminopropan-2-ol"
            },
            :"http://rdf.chemspider.com/"=>{
              :uri=>"http://rdf.chemspider.com/3",
              :inchi=>"InChI=1S/C3H9NO/c1-3(5)2-4/h3,5H,2,4H2,1H3",
              :inchikey=>"HXKKHQJGJAFBHI-UHFFFAOYSA-N",
              :smiles=>"OC(C)CN",
              :ro5_violations=>0
            }
          },
          :on_assay=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL759677",
            :description=>"Inhibitory activity against Plasmodium falciparum",
            :target=>{
              :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL364",
              :title=>"Plasmodium falciparum",
              :organism=>"Plasmodium falciparum"
            },
            :organism=>"Plasmodium falciparum"
          },
          :relation=>"=", :standard_units=>"nM", :standard_value=>800000, :activity_type=>"IC50", :activity_value=>800000
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
        @client.compound_pharmacology_count(VALID_COMPOUND_URI).should == {:uri => VALID_COMPOUND_URI, :count => 2}
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
            :alternative_name=>["Sodium channel protein type X subunit alpha", "Peripheral nerve sodium channel 3", "Voltage-gated sodium channel subunit alpha Nav1.8"],
            :classified_with=>["http://purl.uniprot.org/go/0007600", "http://purl.uniprot.org/keywords/832", "http://purl.uniprot.org/go/0044299", "http://purl.uniprot.org/keywords/894", "http://purl.uniprot.org/keywords/851", "http://purl.uniprot.org/keywords/677", "http://purl.uniprot.org/keywords/621", "http://purl.uniprot.org/go/0001518", "http://purl.uniprot.org/keywords/1133", "http://purl.uniprot.org/keywords/325", "http://purl.uniprot.org/keywords/1185", "http://purl.uniprot.org/go/0005248", "http://purl.uniprot.org/go/0035725"],
            :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence",
            :organism=>"http://purl.uniprot.org/taxonomy/9606",
            :sequence=>"MEFPIGSLETNNFRRFTPESLVEIEKQIAAKQGTKKAREKHREQKDQEEKPRPQLDLKACNQLPKFYGELPAELIGEPLEDLDPFYSTHRTFMVLNKGRTISRFSATRALWLFSPFNLIRRTAIKVSVHSWFSLFITVTILVNCVCMTRTDLPEKIEYVFTVIYTFEALIKILARGFCLNEFTYLRDPWNWLDFSVITLAYVGTAIDLRGISGLRTFRVLRALKTVSVIPGLKVIVGALIHSVKKLADVTILTIFCLSVFALVGLQLFKGNLKNKCVKNDMAVNETTNYSSHRKPDIYINKRGTSDPLLCGNGSDSGHCPDGYICLKTSDNPDFNYTSFDSFAWAFLSLFRLMTQDSWERLYQQTLRTSGKIYMIFFVLVIFLGSFYLVNLILAVVTMAYEEQNQATTDEIEAKEKKFQEALEMLRKEQEVLAALGIDTTSLHSHNGSPLTSKNASERRHRIKPRVSEGSTEDNKSPRSDPYNQRRMSFLGLASGKRRASHGSVFHFRSPGRDISLPEGVTDDGVFPGDHESHRGSLLLGGGAGQQGPLPRSPLPQPSNPDSRHGEDEHQPPPTSELAPGAVDVSAFDAGQKKTFLSAEYLDEPFRAQRAMSVVSIITSVLEELEESEQKCPPCLTSLSQKYLIWDCCPMWVKLKTILFGLVTDPFAELTITLCIVVNTIFMAMEHHGMSPTFEAMLQIGNIVFTIFFTAEMVFKIIAFDPYYYFQKKWNIFDCIIVTVSLLELGVAKKGSLSVLRSFRLLRVFKLAKSWPTLNTLIKIIGNSVGALGNLTIILAIIVFVFALVGKQLLGENYRNNRKNISAPHEDWPRWHMHDFFHSFLIVFRILCGEWIENMWACMEVGQKSICLILFLTVMVLGNLVVLNLFIALLLNSFSADNLTAPEDDGEVNNLQVALARIQVFGHRTKQALCSFFSRSCPFPQPKAEPELVVKLPLSSSKAENHIAANTARGSSGGLQAPRGPRDEHSDFIANPTVWVSVPIAEGESDLDDLEDDGGEDAQSFQQEVIPKGQQEQLQQVERCGDHLTPRSPGTGTSSEDLAPSLGETWKDESVPQVPAEGVDDTSSSEGSTVDCLDPEEILRKIPELADDLEEPDDCFTEGCIRHCPCCKLDTTKSPWDVGWQVRKTCYRIVEHSWFESFIIFMILLSSGSLAFEDYYLDQKPTVKALLEYTDRVFTFIFVFEMLLKWVAYGFKKYFTNAWCWLDFLIVNISLISLTAKILEYSEVAPIKALRTLRALRPLRALSRFEGMRVVVDALVGAIPSIMNVLLVCLIFWLIFSIMGVNLFAGKFWRCINYTDGEFSLVPLSIVNNKSDCKIQNSTGSFFWVNVKVNFDNVAMGYLALLQVATFKGWMDIMYAAVDSREVNMQPKWEDNVYMYLYFVIFIIFGGFFTLNLFVGVIIDNFNQQKKKLGGQDIFMTEEQKKYYNAMKKLGSKKPQKPIPRPLNKFQGFVFDIVTRQAFDITIMVLICLNMITMMVETDDQSEEKTKILGKINQFFVAVFTGECVMKMFALRQYYFTNGWNVFDFIVVVLSIASLIFSAILKSLQSYFSPTLFRVIRLARIGRILRLIRAAKGIRTLLFALMMSLPALFNIGLLLFLVMFIYSIFGMSSFPHVRWEAGIDDMFNFQTFANSMLCLFQITTSAGWDGLLSPILNTGPPYCDPNLPNSNGTRGDCGSPAVGIIFFTTYIIISFLIMVNMYIAVILENFNVATEESTEPLSEDDFDMFYETWEKFDPEATQFITFSALSDFADTLSGPLRIPKPNRNILIQMDLPLVPGDKIHCLDILFAFTKNVLGESGELDSLKANMEEKFMATNLSKSSYEPIATTLRWKQEDISATVIQKAYRSYVLHRSMALSNTPCVPRAEEEAASLPDEGFVAFTANENCVLPDKSETASATSFPPSYESVTRGLSDRVNMRTSSSIQNEDEATSMELIAPGP"
          },
          :"http://linkedlifedata.com/resource/drugbank"=>{
            :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198",
            :cellular_location=>["membrane", "multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough"],
            :molecular_weight=>"220568", :number_of_residues=>"1988", :theoretical_pi=>"5.77"
          },
          :"http://data.kasabi.com/dataset/chembl-rdf"=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451",
            :description=>"Sodium channel protein type 10 subunit alpha",
            :keyword=>["Polymorphism", "Repeat", "Reference proteome", "Sodium", "Ubl conjugation", "Sodium channel", "Complete proteome", "Ion transport", "Transmembrane", "Ionic channel", "Transport", "Sodium transport", "Voltage-gated channel", "Membrane", "Glycoprotein", "Transmembrane helix"],
            :sub_class_of=>"http://purl.obolibrary.org/obo#PR_000000001"
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
        result[:items].count.should == 186
        result[:items].first.should == {
          :uri=>"http://data.kasabi.com/dataset/chembl-rdf/activity/a1668044",
          :pmid=>"16392798",
          :for_molecule=>{
            :"http://data.kasabi.com/dataset/chembl-rdf"=>{
              :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL199824",
              :full_mwt=>422.497
            },
            :"http://rdf.chemspider.com/"=>{
              :uri=>"http://rdf.chemspider.com/9850903",
              :inchi=>"InChI=1S/C23H29N5O3/c1-25-22(29)17-24-28(23(25)30)11-4-3-10-26-12-14-27(15-13-26)21-7-5-6-18-8-9-19(31-2)16-20(18)21/h5-9,16-17H,3-4,10-15H2,1-2H3/i2-1",
              :inchikey=>"GKTQBPYMIGXPKG-JVVVGQRLSA-N",
              :smiles=>"Cn1c(=O)cnn(c1=O)CCCCN2CCN(CC2)c3cccc4c3cc(cc4)OC"
            },
            :"http://www.conceptwiki.org/"=>{
              :uri=>"http://www.conceptwiki.org/concept/28289bc2-ed2f-451c-93c4-05b2581877a0",
              :pref_label_en=>"4-methyl-2-[4-(4-{7-[(~11~C)methyloxy]naphthalen-1-yl}piperazin-1-yl)butyl]-1,2,4-triazine-3,5(2H,4H)-dione",
              :pref_label=>"4-methyl-2-[4-(4-{7-[(~11~C)methyloxy]naphthalen-1-yl}piperazin-1-yl)butyl]-1,2,4-triazine-3,5(2H,4H)-dione"
            }
          },
          :on_assay=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL868783",
            :description=>"Binding affinity to sodium channel",
            :target=>{
              :"http://data.kasabi.com/dataset/chembl-rdf"=>{
                :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451",
                :title=>"Sodium channel protein type X alpha subunit",
                :target_organism=>"Homo sapiens"
              }
            }
          },
          :relation=>">",
          :standard_units=>"nM",
          :standard_value=>10000,
          :activity_type=>"Ki"
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
        @client.target_pharmacology_count(VALID_TARGET_URI).should == {:uri=>VALID_TARGET_URI, :count=>186}
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
        @client.smiles_to_url(VALID_SMILES).should == {:smiles=>VALID_SMILES, :uri=>'http://rdf.chemspider.com/7555'}
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
        expect {@client.similarity_search(UNKNOWN_SMILES)}.to raise_error OPS::GatewayTimeoutError
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
        @client.similarity_search(VALID_SMILES, 'resultOptions.Limit' => 5).should == {
          :limit => "5",
          :molecule => VALID_SMILES,
          :result => [
            "http://rdf.chemspider.com/349",
            "http://rdf.chemspider.com/350",
            "http://rdf.chemspider.com/347",
            "http://rdf.chemspider.com/348",
            "http://rdf.chemspider.com/352"
          ],
          :type => "SimilaritySearch"
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.similarity_search(VALID_SMILES, 'resultOptions.Limit' => 5).should_not be_nil
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
        expect {@client.substructure_search(UNKNOWN_SMILES)}.to raise_error OPS::NotFoundError
      end

      it 'raises InternalServerError if the smiles is invalid' do
        expect {@client.substructure_search(INVALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it 'raises InternalServerError if an OPS internal server error occurs' do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/substructure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:status => 500)
        expect {@client.substructure_search(VALID_SMILES)}.to raise_error OPS::InternalServerError
      end

      it "raises an ArgumentError if no smiles URI is given" do
        expect {@client.substructure_search}.to raise_error(ArgumentError)
      end

      it "returns results if the smiles is known to OPS" do
        @client.substructure_search(VALID_SMILES, 'resultOptions.Limit' => 5).should == {
          :limit => "5",
          :molecule => VALID_SMILES,
          :result => [
            "http://rdf.chemspider.com/349",
            "http://rdf.chemspider.com/360",
            "http://rdf.chemspider.com/347",
            "http://rdf.chemspider.com/354",
            "http://rdf.chemspider.com/355"
          ],
          :type => "SubstructureSearch"
        }
      end

      it "works with a server URL with trailing backslash" do
        config = OPS_SETTINGS.dup
        config[:url] += '/'
        @client = OPS::OpenPhactsClient.new(config)
        @client.substructure_search(VALID_SMILES, 'resultOptions.Limit' => 5).should_not be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{OPS_SETTINGS[:url]}/structure/substructure?_format=json&app_id=#{OPS_SETTINGS[:app_id]}&app_key=#{OPS_SETTINGS[:app_key]}&searchOptions.Molecule=#{VALID_SMILES}").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})
        expect {@client.substructure_search(VALID_SMILES)}.to raise_error(OPS::InvalidJsonResponse, "Could not parse response")
      end
    end
  end


end
