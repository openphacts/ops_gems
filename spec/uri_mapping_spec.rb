require 'spec_helper'

describe OPS::URIMapping do
  it "resolves a ChemSpider URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.chemspider.com/187440").should == "http://www.chemspider.com/Chemical-Structure.187440.html"
  end

  it "resolves a Chembl RDF molecule URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734").should == "http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734.html"
  end

  it "resolves a Chembl RDF target URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/target/t30003").should == "http://data.kasabi.com/dataset/chembl-rdf/target/t30003.html"
  end

  it "resolves a DrukBank URI" do
    OPS::URIMapping.new.resolve_uri("http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398").should == "http://www4.wiwiss.fu-berlin.de/drugbank/page/drugs/DB00398"
  end

  it "returns nil if the URI can't be resolved" do
    OPS::URIMapping.new.resolve_uri("http://www.unknown.com/molecule/1234").should be_nil
  end
end