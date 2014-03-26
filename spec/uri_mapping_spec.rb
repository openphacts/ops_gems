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
  it "does not change a rsc URI" do
    OPS::URIMapping.new.resolve_uri("http://ops.rsc.org/OPS100").should == "http://ops.rsc.org/OPS100"
  end

  it "does not change a rsc-us URI" do
    OPS::URIMapping.new.resolve_uri("http://ops.rsc-us.org/OPS100").should == "http://ops.rsc-us.org/OPS100"
  end

  it "resolves a Chembl RDF molecule URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.ebi.ac.uk/resource/chembl/molecule/CHEMBL25").should == "http://www.ebi.ac.uk/chembl/compound/inspect/CHEMBL25"
  end

  it "resolves a Chembl RDF target URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.ebi.ac.uk/resource/chembl/target/CHEMBL25").should == "http://www.ebi.ac.uk/chembl/target/inspect/CHEMBL25"
  end

  it "resolves a Chembl RDF activity URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.ebi.ac.uk/resource/chembl/activity/CHEMBL_ACT_2500").should == "http://www.ebi.ac.uk/rdf/services/chembl/describe?uri=http://rdf.ebi.ac.uk/resource/chembl/activity/CHEMBL_ACT_2500"
  end

  it "resolves a Chembl RDF assay URI" do
    OPS::URIMapping.new.resolve_uri("http://rdf.ebi.ac.uk/resource/chembl/assay/CHEMBL2500").should == "http://www.ebi.ac.uk/chembl/assay/inspect/CHEMBL2500"
  end

  it "resolves a DrugBank URI" do
    OPS::URIMapping.new.resolve_uri("http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398").should == "http://www.drugbank.ca/drugs/DB00398"
  end

  it "resolves a DrugBank URI" do
    OPS::URIMapping.new.resolve_uri("http://wifo5-03.informatik.uni-mannheim.de/drugbank/page/drugs/DB00945").should == "http://www.drugbank.ca/drugs/DB00945"
  end

  it "resolves a DrugBank traget URI" do
    OPS::URIMapping.new.resolve_uri("http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/198").should == "http://wifo5-03.informatik.uni-mannheim.de/drugbank/page/targets/198"
  end

  it "resolves a ConceptWiki URI" do
    OPS::URIMapping.new.resolve_uri("http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5").should == "http://www.conceptwiki.org/concept/index/38932552-111f-4a4e-a46a-4ed1d7bdf9d5"
  end

  it "resolves a uniprot URI" do
    OPS::URIMapping.new.resolve_uri("http://purl.uniprot.org/uniprot/P07589").should == "http://www.uniprot.org/uniprot/P07589"
  end

  it "returns nil if the URI can't be resolved" do
    OPS::URIMapping.new.resolve_uri("http://www.unknown.com/molecule/1234").should be_nil
  end
end
