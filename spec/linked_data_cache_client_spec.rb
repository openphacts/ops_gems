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

LINKEDDATACACHEURL = 'http://api.openphacts.org'

describe OPS::LinkedDataCacheClient, :vcr do
  describe "initialization" do
    it "takes the server URL" do
      OPS::LinkedDataCacheClient.new(LINKEDDATACACHEURL)
    end

    it "raises an ArgumentError if no server URL is given" do
      expect {
        OPS::LinkedDataCacheClient.new
      }.to raise_exception(ArgumentError)
    end

    it "sets the receiving timeout to 60 by default" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(60).once

      OPS::LinkedDataCacheClient.new(LINKEDDATACACHEURL)
    end

    it "uses a defined receiving timeout" do
      flexmock(HTTPClient).new_instances.should_receive(:receive_timeout=).with(23).once

      OPS::LinkedDataCacheClient.new(LINKEDDATACACHEURL, :receive_timeout => 23)
    end
  end

  describe 'compound' do # ====================================================
    before :each do
      @client = OPS::LinkedDataCacheClient.new(LINKEDDATACACHEURL)
    end

    describe "_info" do # -----------------------------------------------------
      before :each do
        @uri = 'http://rdf.chemspider.com/187440'
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {
          @client.compound_info
        }.to raise_exception(ArgumentError)
      end

      it "returns the compound info if the compound is known to OPS" do
        @client.compound_info(@uri).should == {
          :"http://www.chemspider.com"=>{
            :uri=>"http://rdf.chemspider.com/187440", 
            :inchi=>"InChI=1S/C21H16ClF3N4O3/c1-26-19(30)18-11-15(8-9-27-18)32-14-5-2-12(3-6-14)28-20(31)29-13-4-7-17(22)16(10-13)21(23,24)25/h2-11H,1H3,(H,26,30)(H2,28,29,31)", 
            :inchikey=>"MLDQJTXFUGDVEO-UHFFFAOYSA-N", 
            :smiles=>"CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl", 
            :hba=>7, 
            :hbd=>3, 
            :logp=>4.818, 
            :psa=>9.235e-18, 
            :ro5_violations=>0, 
            :exact_match=>[
              "http://rdf.chemspider.com/187440", 
              {
                :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL1336", 
                :full_mwt=>464.825, 
                :molform=>"C21H16ClF3N4O3", 
                :mw_freebase=>464.825, :rtb=>6
              }, 
              {
                :uri=>"http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5", 
                :pref_label=>"Sorafenib"
              }, 
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398", 
                :biotransformation=>"Sorafenib is metabolized primarily in the liver, undergoing oxidative metabolism, mediated by CYP3A4, as well as glucuronidation mediated by UGT1A9. Sorafenib accounts for approximately 70-85% of the circulating analytes in plasma at steady- state. Eight metabolites of sorafenib have been identified, of which five have been detected in plasma. The main circulating metabolite of sorafenib in plasma, the pyridine N-oxide, shows <i>in vitro</i> potency similar to that of sorafenib. This metabolite comprises approximately 9-16% of circulating analytes at steady-state.", 
                :description=>"Sorafenib (rINN), marketed as Nexavar by Bayer, is a drug approved for the treatment of advanced renal cell carcinoma (primary kidney cancer). It has also received \"Fast Track\" designation by the FDA for the treatment of advanced hepatocellular carcinoma (primary liver cancer), and has since performed well in Phase III trials.\nSorafenib is a small molecular inhibitor of Raf kinase, PDGF (platelet-derived growth factor), VEGF receptor 2 & 3 kinases and c Kit the receptor for Stem cell factor. A growing number of drugs target most of these pathways. The originality of Sorafenib lays in its simultaneous targeting of the Raf/Mek/Erk pathway.", 
                :protein_binding=>"99.5%", 
                :toxicity=>"The highest dose of sorafenib studied clinically is 800 mg twice daily. The adverse reactions observed at this dose were primarily diarrhea and dermatologic events. No information is available on symptoms of acute overdose in animals because of the saturation of absorption in oral acute toxicity studies conducted in animals."
              }
            ]
          }, 
          :"http://data.kasabi.com/dataset/chembl-rdf"=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL1336", 
            :full_mwt=>464.825, :molform=>"C21H16ClF3N4O3", 
            :mw_freebase=>464.825, 
            :rtb=>6
          }, 
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5", 
            :pref_label=>"Sorafenib"
          },
          :"http://linkedlifedata.com/resource/drugbank"=>{:uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398", 
            :biotransformation=>"Sorafenib is metabolized primarily in the liver, undergoing oxidative metabolism, mediated by CYP3A4, as well as glucuronidation mediated by UGT1A9. Sorafenib accounts for approximately 70-85% of the circulating analytes in plasma at steady- state. Eight metabolites of sorafenib have been identified, of which five have been detected in plasma. The main circulating metabolite of sorafenib in plasma, the pyridine N-oxide, shows <i>in vitro</i> potency similar to that of sorafenib. This metabolite comprises approximately 9-16% of circulating analytes at steady-state.", 
            :description=>"Sorafenib (rINN), marketed as Nexavar by Bayer, is a drug approved for the treatment of advanced renal cell carcinoma (primary kidney cancer). It has also received \"Fast Track\" designation by the FDA for the treatment of advanced hepatocellular carcinoma (primary liver cancer), and has since performed well in Phase III trials.\nSorafenib is a small molecular inhibitor of Raf kinase, PDGF (platelet-derived growth factor), VEGF receptor 2 & 3 kinases and c Kit the receptor for Stem cell factor. A growing number of drugs target most of these pathways. The originality of Sorafenib lays in its simultaneous targeting of the Raf/Mek/Erk pathway.", 
            :protein_binding=>"99.5%", 
            :toxicity=>"The highest dose of sorafenib studied clinically is 800 mg twice daily. The adverse reactions observed at this dose were primarily diarrhea and dermatologic events. No information is available on symptoms of acute overdose in animals because of the saturation of absorption in oral acute toxicity studies conducted in animals."
          }
        }

      end

      it "returns nil if the compound is unknown to OPS" do
        @client.compound_info("http://unknown.com/1111").should be_nil
      end

      it "raises an exception if response can't be parsed" do
        stub_request(:get, "#{LINKEDDATACACHEURL}/compound.json?uri=http://unknown.com/1111").
          to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.compound_info("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::InvalidResponse, "Could not parse response")
      end

      it "raises an exception if the HTTP return code is not 200" do
        stub_request(:get, "#{LINKEDDATACACHEURL}/compound.json?uri=http://unknown.com/1111").
          to_return(:status => 500,
                    :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.compound_info("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
      end

      it "works with a server URL with trailing backslash" do
        @client = OPS::LinkedDataCacheClient.new("#{LINKEDDATACACHEURL}/")
        @client.compound_info(@uri).should_not be_nil
      end
    end # ---------------------------------------------------------------------

    describe "_pharmacology" do # ---------------------------------------------
      before :each do
        @uri = 'http://rdf.chemspider.com/2157'
      end

      it "raises an ArgumentError if no compound URI is given" do
        expect {
          @client.compound_pharmacology
        }.to raise_exception(ArgumentError)
      end

      it "works for a known compound with targets" do
        @client.compound_pharmacology(@uri).should_not be_nil
      end

      it "raises an exception if the HTTP return code is not 200" do
        stub_request(:get, "#{LINKEDDATACACHEURL}/compound/pharmacology.json?uri=http://unknown.com/1111").
          to_return(:status => 500,
                    :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.compound_pharmacology("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
      end

      it "works with a server URL with trailing backslash" do
        @client = OPS::LinkedDataCacheClient.new("#{LINKEDDATACACHEURL}/")
        @client.compound_pharmacology(@uri).should_not be_nil
      end

      it "returns results for using the chemspider URI" do
        @client.compound_pharmacology(@uri).should_not be_nil
      end

      it "returns results for using the conceptwiki URI" do
        uri = 'http://www.conceptwiki.org/concept/dd758846-1dac-4f0d-a329-06af9a7fa413'
        @client.compound_pharmacology(uri).should_not be_nil
      end

      it "returns results even if some assays do not have targets" do
        uri = 'http://rdf.chemspider.com/1004'
        @client.compound_pharmacology(uri).should_not be_nil
      end

      it "returns and array of assays if they exist" do
        result = @client.compound_pharmacology(@uri)
        result[:"http://data.kasabi.com/dataset/chembl-rdf"].has_key?(:activity).should == true
        result[:"http://data.kasabi.com/dataset/chembl-rdf"][:activity].is_a?(Array).should == true
      end

    end # ---------------------------------------------------------------------

  end # =======================================================================



  describe 'target' do # ======================================================
    before :each do
      @client = OPS::LinkedDataCacheClient.new(LINKEDDATACACHEURL)
      #@uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL4597'
      @uri = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
    end

    describe '_info' do # -----------------------------------------------------
      it "raises an ArgumentError if no compound URI is given" do
        expect {
          @client.target_info
        }.to raise_exception(ArgumentError)
      end

      it "raises an exception if the HTTP return code is not 200" do
        stub_request(:get, "#{LINKEDDATACACHEURL}/target.json?uri=http://unknown.com/1111").
          to_return(:status => 500,
                    :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.target_info("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
      end

      it "returns results for a conceptwiki URI" do
        uri = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
        @client.target_info(uri).should_not be_nil
      end

      it "returns results for a chembl URI" do
        uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451'
        @client.target_info(uri).should_not be_nil
      end

      it "returns the target object" do
        @client.target_info(@uri).should == {
          :"http://www.conceptwiki.org"=>{
            :uri=>"http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291", 
            :exact_match=>[
              {
                :uri=>"http://purl.uniprot.org/uniprot/Q9Y5Y9", 
                :function_annotation=>"This protein mediates the voltage-dependent sodium ion permeability of excitable membranes. Assuming opened or closed conformations in response to the voltage difference across the membrane, the protein forms a sodium-selective channel through which sodium ions may pass in accordance with their electrochemical gradient. It is a tetrodotoxin-resistant sodium channel isoform. Its electrophysiological properties vary depending on the type of the associated beta subunits (in vitro). Plays a role in neuropathic pain mechanisms (By similarity).", 
                :alternative_name=>"Peripheral nerve sodium channel 3 , Sodium channel protein type X subunit alpha , Voltage-gated sodium channel subunit alpha Nav1.8", 
                :classified_with=>[
                  "http://purl.uniprot.org/keywords/325", 
                  "http://purl.uniprot.org/keywords/832", 
                  "http://purl.uniprot.org/go/0001518", 
                  "http://purl.uniprot.org/keywords/894", 
                  "http://purl.uniprot.org/keywords/677", 
                  "http://purl.uniprot.org/go/0035725", 
                  "http://purl.uniprot.org/go/0007600", 
                  "http://purl.uniprot.org/keywords/851", 
                  "http://purl.uniprot.org/keywords/621", 
                  "http://purl.uniprot.org/go/0044299", 
                  "http://purl.uniprot.org/go/0005248", 
                  "http://purl.uniprot.org/keywords/1133", 
                  "http://purl.uniprot.org/keywords/1185"
                ], 
                :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence", 
                :organism=>"http://purl.uniprot.org/taxonomy/9606", 
                :sequence=>"MEFPIGSLETNNFRRFTPESLVEIEKQIAAKQGTKKAREKHREQKDQEEKPRPQLDLKACNQLPKFYGELPAELIGEPLEDLDPFYSTHRTFMVLNKGRTISRFSATRALWLFSPFNLIRRTAIKVSVHSWFSLFITVTILVNCVCMTRTDLPEKIEYVFTVIYTFEALIKILARGFCLNEFTYLRDPWNWLDFSVITLAYVGTAIDLRGISGLRTFRVLRALKTVSVIPGLKVIVGALIHSVKKLADVTILTIFCLSVFALVGLQLFKGNLKNKCVKNDMAVNETTNYSSHRKPDIYINKRGTSDPLLCGNGSDSGHCPDGYICLKTSDNPDFNYTSFDSFAWAFLSLFRLMTQDSWERLYQQTLRTSGKIYMIFFVLVIFLGSFYLVNLILAVVTMAYEEQNQATTDEIEAKEKKFQEALEMLRKEQEVLAALGIDTTSLHSHNGSPLTSKNASERRHRIKPRVSEGSTEDNKSPRSDPYNQRRMSFLGLASGKRRASHGSVFHFRSPGRDISLPEGVTDDGVFPGDHESHRGSLLLGGGAGQQGPLPRSPLPQPSNPDSRHGEDEHQPPPTSELAPGAVDVSAFDAGQKKTFLSAEYLDEPFRAQRAMSVVSIITSVLEELEESEQKCPPCLTSLSQKYLIWDCCPMWVKLKTILFGLVTDPFAELTITLCIVVNTIFMAMEHHGMSPTFEAMLQIGNIVFTIFFTAEMVFKIIAFDPYYYFQKKWNIFDCIIVTVSLLELGVAKKGSLSVLRSFRLLRVFKLAKSWPTLNTLIKIIGNSVGALGNLTIILAIIVFVFALVGKQLLGENYRNNRKNISAPHEDWPRWHMHDFFHSFLIVFRILCGEWIENMWACMEVGQKSICLILFLTVMVLGNLVVLNLFIALLLNSFSADNLTAPEDDGEVNNLQVALARIQVFGHRTKQALCSFFSRSCPFPQPKAEPELVVKLPLSSSKAENHIAANTARGSSGGLQAPRGPRDEHSDFIANPTVWVSVPIAEGESDLDDLEDDGGEDAQSFQQEVIPKGQQEQLQQVERCGDHLTPRSPGTGTSSEDLAPSLGETWKDESVPQVPAEGVDDTSSSEGSTVDCLDPEEILRKIPELADDLEEPDDCFTEGCIRHCPCCKLDTTKSPWDVGWQVRKTCYRIVEHSWFESFIIFMILLSSGSLAFEDYYLDQKPTVKALLEYTDRVFTFIFVFEMLLKWVAYGFKKYFTNAWCWLDFLIVNISLISLTAKILEYSEVAPIKALRTLRALRPLRALSRFEGMRVVVDALVGAIPSIMNVLLVCLIFWLIFSIMGVNLFAGKFWRCINYTDGEFSLVPLSIVNNKSDCKIQNSTGSFFWVNVKVNFDNVAMGYLALLQVATFKGWMDIMYAAVDSREVNMQPKWEDNVYMYLYFVIFIIFGGFFTLNLFVGVIIDNFNQQKKKLGGQDIFMTEEQKKYYNAMKKLGSKKPQKPIPRPLNKFQGFVFDIVTRQAFDITIMVLICLNMITMMVETDDQSEEKTKILGKINQFFVAVFTGECVMKMFALRQYYFTNGWNVFDFIVVVLSIASLIFSAILKSLQSYFSPTLFRVIRLARIGRILRLIRAAKGIRTLLFALMMSLPALFNIGLLLFLVMFIYSIFGMSSFPHVRWEAGIDDMFNFQTFANSMLCLFQITTSAGWDGLLSPILNTGPPYCDPNLPNSNGTRGDCGSPAVGIIFFTTYIIISFLIMVNMYIAVILENFNVATEESTEPLSEDDFDMFYETWEKFDPEATQFITFSALSDFADTLSGPLRIPKPNRNILIQMDLPLVPGDKIHCLDILFAFTKNVLGESGELDSLKANMEEKFMATNLSKSSYEPIATTLRWKQEDISATVIQKAYRSYVLHRSMALSNTPCVPRAEEEAASLPDEGFVAFTANENCVLPDKSETASATSFPPSYESVTRGLSDRVNMRTSSSIQNEDEATSMELIAPGP"
              }, 
              {
                :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198", 
                :cellular_location=>"multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough , membrane", 
                :molecular_weight=>"220568", 
                :number_of_residues=>"1988", 
                :theoretical_pi=>"5.77"
              }, 
              {
                :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451", 
                :description=>"Sodium channel protein type 10 subunit alpha", 
                :keyword=>"Sodium , Complete proteome , Glycoprotein , Ion transport , Ionic channel , Membrane , Polymorphism , Reference proteome , Repeat , Sodium channel , Sodium transport , Transmembrane , Transmembrane helix , Transport , Ubl conjugation , Voltage-gated channel", 
                :label=>"CHEMBL5451 , Sodium channel protein type 10 subunit alpha , Sodium channel protein type X subunit alpha , PN3 , Peripheral nerve sodium channel 3 , hPN3 , Voltage-gated sodium channel subunit alpha Nav1.8", 
                :sub_class_of=>"http://purl.obolibrary.org/obo#PR_000000001"
              }, 
              "http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291"
            ], 
            :pref_label=>"Sodium channel protein type 10 subunit alpha (Homo sapiens)"
          }, 
          :"http://purl.uniprot.org"=>{
            :uri=>"http://purl.uniprot.org/uniprot/Q9Y5Y9", 
            :function_annotation=>"This protein mediates the voltage-dependent sodium ion permeability of excitable membranes. Assuming opened or closed conformations in response to the voltage difference across the membrane, the protein forms a sodium-selective channel through which sodium ions may pass in accordance with their electrochemical gradient. It is a tetrodotoxin-resistant sodium channel isoform. Its electrophysiological properties vary depending on the type of the associated beta subunits (in vitro). Plays a role in neuropathic pain mechanisms (By similarity).", 
            :alternative_name=>"Peripheral nerve sodium channel 3 , Sodium channel protein type X subunit alpha , Voltage-gated sodium channel subunit alpha Nav1.8", 
            :classified_with=>[
              "http://purl.uniprot.org/keywords/325", 
              "http://purl.uniprot.org/keywords/832", 
              "http://purl.uniprot.org/go/0001518", 
              "http://purl.uniprot.org/keywords/894", 
              "http://purl.uniprot.org/keywords/677", 
              "http://purl.uniprot.org/go/0035725", 
              "http://purl.uniprot.org/go/0007600", 
              "http://purl.uniprot.org/keywords/851", 
              "http://purl.uniprot.org/keywords/621", 
              "http://purl.uniprot.org/go/0044299", 
              "http://purl.uniprot.org/go/0005248", 
              "http://purl.uniprot.org/keywords/1133", 
              "http://purl.uniprot.org/keywords/1185"
            ], 
            :existence=>"http://purl.uniprot.org/core/Evidence_at_Protein_Level_Existence", 
            :organism=>"http://purl.uniprot.org/taxonomy/9606", 
            :sequence=>"MEFPIGSLETNNFRRFTPESLVEIEKQIAAKQGTKKAREKHREQKDQEEKPRPQLDLKACNQLPKFYGELPAELIGEPLEDLDPFYSTHRTFMVLNKGRTISRFSATRALWLFSPFNLIRRTAIKVSVHSWFSLFITVTILVNCVCMTRTDLPEKIEYVFTVIYTFEALIKILARGFCLNEFTYLRDPWNWLDFSVITLAYVGTAIDLRGISGLRTFRVLRALKTVSVIPGLKVIVGALIHSVKKLADVTILTIFCLSVFALVGLQLFKGNLKNKCVKNDMAVNETTNYSSHRKPDIYINKRGTSDPLLCGNGSDSGHCPDGYICLKTSDNPDFNYTSFDSFAWAFLSLFRLMTQDSWERLYQQTLRTSGKIYMIFFVLVIFLGSFYLVNLILAVVTMAYEEQNQATTDEIEAKEKKFQEALEMLRKEQEVLAALGIDTTSLHSHNGSPLTSKNASERRHRIKPRVSEGSTEDNKSPRSDPYNQRRMSFLGLASGKRRASHGSVFHFRSPGRDISLPEGVTDDGVFPGDHESHRGSLLLGGGAGQQGPLPRSPLPQPSNPDSRHGEDEHQPPPTSELAPGAVDVSAFDAGQKKTFLSAEYLDEPFRAQRAMSVVSIITSVLEELEESEQKCPPCLTSLSQKYLIWDCCPMWVKLKTILFGLVTDPFAELTITLCIVVNTIFMAMEHHGMSPTFEAMLQIGNIVFTIFFTAEMVFKIIAFDPYYYFQKKWNIFDCIIVTVSLLELGVAKKGSLSVLRSFRLLRVFKLAKSWPTLNTLIKIIGNSVGALGNLTIILAIIVFVFALVGKQLLGENYRNNRKNISAPHEDWPRWHMHDFFHSFLIVFRILCGEWIENMWACMEVGQKSICLILFLTVMVLGNLVVLNLFIALLLNSFSADNLTAPEDDGEVNNLQVALARIQVFGHRTKQALCSFFSRSCPFPQPKAEPELVVKLPLSSSKAENHIAANTARGSSGGLQAPRGPRDEHSDFIANPTVWVSVPIAEGESDLDDLEDDGGEDAQSFQQEVIPKGQQEQLQQVERCGDHLTPRSPGTGTSSEDLAPSLGETWKDESVPQVPAEGVDDTSSSEGSTVDCLDPEEILRKIPELADDLEEPDDCFTEGCIRHCPCCKLDTTKSPWDVGWQVRKTCYRIVEHSWFESFIIFMILLSSGSLAFEDYYLDQKPTVKALLEYTDRVFTFIFVFEMLLKWVAYGFKKYFTNAWCWLDFLIVNISLISLTAKILEYSEVAPIKALRTLRALRPLRALSRFEGMRVVVDALVGAIPSIMNVLLVCLIFWLIFSIMGVNLFAGKFWRCINYTDGEFSLVPLSIVNNKSDCKIQNSTGSFFWVNVKVNFDNVAMGYLALLQVATFKGWMDIMYAAVDSREVNMQPKWEDNVYMYLYFVIFIIFGGFFTLNLFVGVIIDNFNQQKKKLGGQDIFMTEEQKKYYNAMKKLGSKKPQKPIPRPLNKFQGFVFDIVTRQAFDITIMVLICLNMITMMVETDDQSEEKTKILGKINQFFVAVFTGECVMKMFALRQYYFTNGWNVFDFIVVVLSIASLIFSAILKSLQSYFSPTLFRVIRLARIGRILRLIRAAKGIRTLLFALMMSLPALFNIGLLLFLVMFIYSIFGMSSFPHVRWEAGIDDMFNFQTFANSMLCLFQITTSAGWDGLLSPILNTGPPYCDPNLPNSNGTRGDCGSPAVGIIFFTTYIIISFLIMVNMYIAVILENFNVATEESTEPLSEDDFDMFYETWEKFDPEATQFITFSALSDFADTLSGPLRIPKPNRNILIQMDLPLVPGDKIHCLDILFAFTKNVLGESGELDSLKANMEEKFMATNLSKSSYEPIATTLRWKQEDISATVIQKAYRSYVLHRSMALSNTPCVPRAEEEAASLPDEGFVAFTANENCVLPDKSETASATSFPPSYESVTRGLSDRVNMRTSSSIQNEDEATSMELIAPGP"
          }, 
          :"http://linkedlifedata.com/resource/drugbank"=>{
            :uri=>"http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198", 
            :cellular_location=>"multi-passMembraneProtein.ItCanBeTranslocatedToTheExtracellularMembraneThrough , membrane", 
            :molecular_weight=>"220568", 
            :number_of_residues=>"1988", 
            :theoretical_pi=>"5.77"
          }, 
          :"http://data.kasabi.com/dataset/chembl-rdf"=>{
            :uri=>"http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451", 
            :description=>"Sodium channel protein type 10 subunit alpha", 
            :keyword=>"Sodium , Complete proteome , Glycoprotein , Ion transport , Ionic channel , Membrane , Polymorphism , Reference proteome , Repeat , Sodium channel , Sodium transport , Transmembrane , Transmembrane helix , Transport , Ubl conjugation , Voltage-gated channel", 
            :label=>"CHEMBL5451 , Sodium channel protein type 10 subunit alpha , Sodium channel protein type X subunit alpha , PN3 , Peripheral nerve sodium channel 3 , hPN3 , Voltage-gated sodium channel subunit alpha Nav1.8", 
            :sub_class_of=>"http://purl.obolibrary.org/obo#PR_000000001"
          }
        } 
      end

    end # ---------------------------------------------------------------------


    describe "_pharmacology" do # ---------------------------------------------
      
      it "raises an ArgumentError if no compound URI is given" do
        expect {
          @client.target_pharmacology
        }.to raise_exception(ArgumentError)
      end

      it "raises an exception if the HTTP return code is not 200" do
        stub_request(:get, "#{LINKEDDATACACHEURL}/target/pharmacology.json?uri=http://unknown.com/1111").
          to_return(:status => 500,
                    :headers => {"Content-Type"=>"application/json; charset=utf-8"})

        expect {
          @client.target_pharmacology("http://unknown.com/1111")
        }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
      end

      it "returns results for a conceptwiki URI" do
        uri = 'http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291'
        @client.target_pharmacology(uri).should_not be_nil
      end

      it "returns results for a chembl URI" do
        uri = 'http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL5451'
        @client.target_pharmacology(uri).should_not be_nil
      end

      it "works for a known target with compounds" do
        @client.target_pharmacology(@uri).should_not be_nil
      end

      it "works with a server URL with trailing backslash" do
        @client = OPS::LinkedDataCacheClient.new("#{LINKEDDATACACHEURL}/")
        @client.target_pharmacology(@uri).should_not be_nil
      end

      it "returns and array of assays if they exist" do
        result = @client.target_pharmacology(@uri)
        result[:"http://data.kasabi.com/dataset/chembl-rdf"].has_key?(:target_of_assay).should == true
        result[:"http://data.kasabi.com/dataset/chembl-rdf"][:target_of_assay].is_a?(Array).should == true
      end

    end # ---------------------------------------------------------------------

  end # =======================================================================

end