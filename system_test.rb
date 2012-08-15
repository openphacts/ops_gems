require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ops'


OPS_URL = "http://ops.few.vu.nl:9187/opsapi"
CHEMSPIDER_TOKEN = ""


raise "No OPS Url defined" if OPS_URL.empty?
raise "No ChemSpider Token defined" if CHEMSPIDER_TOKEN.empty?




OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_tautomers)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_including_h)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_excluding_h)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_isomers)
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).structure_search(%(O=C3C(/Oc1ccccc1)=C(/c2ccc(cc2)S(=O)(=O)C)CC3))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).similarity_search(%(CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl))
OPS::ChemspiderClient.new(CHEMSPIDER_TOKEN).substructure_search(%(O=C(O)c2c(OCCN1C(=O)\\C=C/C1=O)cccc2))