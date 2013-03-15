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

describe OPS::URIMapping do
  it "resolves a ChemSpider URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.chemspider.com/187440").should == "http://www.chemspider.com/Chemical-Structure.187440.html"
  end

  it "resolves a Chembl RDF chemblid URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/chemblid/CHEMBL833860").should == "https://www.ebi.ac.uk/chembldb/compound/inspect/CHEMBL833860"
  end

  it "resolves a Chembl RDF molecule URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734").should == "http://linkedchemistry.info/chembl/molecule/m276734"
  end

  it "resolves a Chembl RDF target URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/target/t30003").should == "http://linkedchemistry.info/chembl/target/t30003"
  end

  it "resolves a Chembl RDF activity URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/activity/a1650150").should == "http://linkedchemistry.info/chembl/activity/a1650150"
  end

  it "resolves a Chembl RDF assay URI" do
    OPS::URIMapping.new.resolve_uri("http://data.kasabi.com/dataset/chembl-rdf/assay/a325031").should == "http://linkedchemistry.info/chembl/assay/a325031"
  end

  it "resolves a DrukBank URI" do
    OPS::URIMapping.new.resolve_uri("http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398").should == "http://www.drugbank.ca/drugs/DB00398"
  end

  it "resolves a DrukBank URI" do
    OPS::URIMapping.new.resolve_uri("http://wifo5-03.informatik.uni-mannheim.de/drugbank/page/drugs/DB00945").should == "http://www.drugbank.ca/drugs/DB00945"
  end

  it "resolves a ConceptWiki URI" do
    OPS::URIMapping.new.resolve_uri("http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5").should == "http://www.conceptwiki.org/wiki/#/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5/view"
  end

  it "returns nil if the URI can't be resolved" do
    OPS::URIMapping.new.resolve_uri("http://www.unknown.com/molecule/1234").should be_nil
  end
end