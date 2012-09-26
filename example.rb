require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ops'


OPS_LINKED_DATA_CACHE_URL = "http://ops2.few.vu.nl"
CHEMSPIDER_TOKEN = ""

raise "No OPS Linked Data Cache Url defined" if OPS_LINKED_DATA_CACHE_URL.empty?
raise "No ChemSpider Token defined" if CHEMSPIDER_TOKEN.empty?



#OPS.log = false



chemspider_client = OPS::SoapChemspiderClient.new(CHEMSPIDER_TOKEN)

chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_tautomers)
chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_including_h)
chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_excluding_h)
chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_isomers)
# Note: Takes some time
chemspider_client.substructure_search(%(O=C(O)c2c(OCCN1C(=O)\\C=C/C1=O)cccc2))
# Note: Takes some time
chemspider_client.similarity_search(%(CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl))



linked_data_cache_client = OPS::LinkedDataCacheClient.new(OPS_LINKED_DATA_CACHE_URL)

linked_data_cache_client.compound_info("http://rdf.chemspider.com/187440")
# Note: Takes some time
linked_data_cache_client.compound_pharmacology_info("http://rdf.chemspider.com/187440")