require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ops'


OPS_URL = "http://ops.few.vu.nl:9187/opsapi"
CHEMSPIDER_TOKEN = ""


raise "No OPS Url defined" if OPS_URL.empty?
raise "No ChemSpider Token defined" if CHEMSPIDER_TOKEN.empty?


def make_core_api_call(method, options)
  OPS::CoreApiCall.new(OPS_URL).request(method, options)
end


OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_tautomers)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_including_h)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_excluding_h)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_isomers)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%(O=C3C(/Oc1ccccc1)=C(/c2ccc(cc2)S(=O)(=O)C)CC3))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).similarity_search(%(CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).substructure_search(%(O=C(O)c2c(OCCN1C(=O)\\C=C/C1=O)cccc2))


make_core_api_call("compoundLookup",
                   :substring => "Sora")
make_core_api_call("proteinLookup",
                   :substring => "reductase")
make_core_api_call("compoundInfo",
                   :uri => "<http://chem2bio2rdf.org/chembl/resource/chembl_compounds/276734>")
make_core_api_call("proteinInfo",
                   :uri => "<http://chem2bio2rdf.org/chembl/resource/chembl_targets/12261>")
make_core_api_call("compoundPharmacology",
                   :uri => "<http://chem2bio2rdf.org/chembl/resource/chembl_compounds/276734>")
make_core_api_call("proteinPharmacology",
                   :uri => "<http://chem2bio2rdf.org/chembl/resource/chembl_targets/12261>")
make_core_api_call("proteinPharmacology",
                   :uri => "<http://www.conceptwiki.org/concept/458eaa59-79a5-448f-9085-9664f6f643af>")
make_core_api_call("chemspiderInfo",
                   :csids => "1,3")
make_core_api_call("subclasses",
                   :uri => "<http://purl.uniprot.org/enzyme/1.8.5.->")
make_core_api_call("superclasses",
                   :uri => "<http://purl.uniprot.org/enzyme/1.8.5.->")
make_core_api_call("sparql",
                   :query => "select * where {?s ?p ?o}")
make_core_api_call("triplesWithSubject",
                   :uri => "<http://purl.uniprot.org/enzyme/1.8.5.->")
make_core_api_call("triplesWithPredicate",
                   :uri => "<http://brenda-enzymes.info/has_ic50_value_of>")
make_core_api_call("triplesWithObject",
                   :literal => "C00019")
make_core_api_call("predicatesForSubject",
                   :uri => "<http://wiki.openphacts.org/index.php/PDSP_DB#44863>")
make_core_api_call("subjectsWithPredicate",
                   :uri => "<http://brenda-enzymes.info/has_ic50_value_of>")
make_core_api_call("predicatesWithObject",
                   :literal => "C00019")
make_core_api_call("objectsOfPredicate",
                   :uri => "<http://brenda-enzymes.info/has_ic50_value_of>")
make_core_api_call("subjects",
                   :predicate => "<http://brenda-enzymes.info/has_ic50_value_of>",
                   :literal => "0.0001")
make_core_api_call("predicates",
                   :predicate => "<http://brenda-enzymes.info/3.6.1.3/ic50/b20f92be747f4fc077819e293de8fdef>",
                   :literal => "0.0001")
make_core_api_call("objects",
                   :subject => "<http://brenda-enzymes.info/3.6.1.3/ic50/b20f92be747f4fc077819e293de8fdef>",
                   :predicate => "<http://brenda-enzymes.info/has_ic50_value_of>")


make_core_api_call("chemicalExactStructureSearch",
                   :smiles => %(O=C3C(/Oc1ccccc1)=C(/c2ccc(cc2)S(=O)(=O)C)CC3),
                   :chemspider_token => CHEMSPIDER_TOKEN)
make_core_api_call("chemicalSimilaritySearch",
                   :smiles => %(CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl),
                   :chemspider_token => CHEMSPIDER_TOKEN)
make_core_api_call("chemicalSubstructureSearch",
                   :smiles => %(O=C(O)c2c(OCCN1C(=O)\\C=C/C1=O)cccc2),
                   :chemspider_token => CHEMSPIDER_TOKEN)
