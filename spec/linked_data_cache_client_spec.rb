require 'spec_helper'

describe OPS::LinkedDataCacheClient, :vcr do
  describe "initialization" do
    it "takes the server URL" do
      OPS::LinkedDataCacheClient.new("http://ops.few.vu.nl")
    end

    it "raises an ArgumentError if no server URL is given" do
      expect {
        OPS::LinkedDataCacheClient.new
      }.to raise_exception(ArgumentError)
    end
  end

  describe "#compound_info" do
    before :each do
      @client = OPS::LinkedDataCacheClient.new("http://ops.few.vu.nl")
    end

    it "raises an ArgumentError if no compound URI is given" do
      expect {
        @client.compound_info
      }.to raise_exception(ArgumentError)
    end

    it "returns the compound info if the compound is known to OPS" do
      @client.compound_info("http://rdf.chemspider.com/187440").should == {
        "http://www.chemspider.com" => {
          :href => "http://rdf.chemspider.com/187440",
          :properties => {
            :smiles => "CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl",
            :inchikey => "MLDQJTXFUGDVEO-UHFFFAOYSA-N",
            :inchi => "InChI=1S/C21H16ClF3N4O3/c1-26-19(30)18-11-15(8-9-27-18)32-14-5-2-12(3-6-14)28-20(31)29-13-4-7-17(22)16(10-13)21(23,24)25/h2-11H,1H3,(H,26,30)(H2,28,29,31)"
          }
        },
        "http://data.kasabi.com/dataset/chembl-rdf" => {
          :href => "http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734",
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
        "http://linkedlifedata.com/resource/drugbank" => {
          :href => "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398",
          :properties => {
            :toxicity => "The highest dose of sorafenib studied clinically is 800 mg twice daily. The adverse reactions observed at this dose were primarily diarrhea and dermatologic events. No information is available on symptoms of acute overdose in animals because of the saturation of absorption in oral acute toxicity studies conducted in animals.",
            :protein_binding => "99.5%",
            :description => "Sorafenib (rINN), marketed as Nexavar by Bayer, is a drug approved for the treatment of advanced renal cell carcinoma (primary kidney cancer). It has also received \"Fast Track\" designation by the FDA for the treatment of advanced hepatocellular carcinoma (primary liver cancer), and has since performed well in Phase III trials.\nSorafenib is a small molecular inhibitor of Raf kinase, PDGF (platelet-derived growth factor), VEGF receptor 2 & 3 kinases and c Kit the receptor for Stem cell factor. A growing number of drugs target most of these pathways. The originality of Sorafenib lays in its simultaneous targeting of the Raf/Mek/Erk pathway.",
            :biotransformation => "Sorafenib is metabolized primarily in the liver, undergoing oxidative metabolism, mediated by CYP3A4, as well as glucuronidation mediated by UGT1A9. Sorafenib accounts for approximately 70-85% of the circulating analytes in plasma at steady- state. Eight metabolites of sorafenib have been identified, of which five have been detected in plasma. The main circulating metabolite of sorafenib in plasma, the pyridine N-oxide, shows <i>in vitro</i> potency similar to that of sorafenib. This metabolite comprises approximately 9-16% of circulating analytes at steady-state."
          }
        },
        "http://www.conceptwiki.org" => {
          :href=>"http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5",
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
      stub_request(:get, "http://ops.few.vu.nl/compound.xml?uri=http://unknown.com/1111").
        to_return(:body => %(bla bla), :headers => {"Content-Type"=>"application/soap+xml; charset=utf-8"})

      @client.compound_info("http://unknown.com/1111").should be_nil
    end

    it "raises an exception if the HTTP return code is not 200" do
      stub_request(:get, "http://ops.few.vu.nl/compound.xml?uri=http://unknown.com/1111").
        to_return(:status => 500,
                  :headers => {"Content-Type"=>"application/soap+xml; charset=utf-8"})

      expect {
        @client.compound_info("http://unknown.com/1111").should be_nil
      }.to raise_exception(OPS::LinkedDataCacheClient::BadStatusCode, "Response with status code 500")
    end

    it "works with a server URL with trailing backslash" do
      @client = OPS::LinkedDataCacheClient.new("http://ops.few.vu.nl/")

      @client.compound_info("http://rdf.chemspider.com/187440").should_not be_nil
    end
  end
end