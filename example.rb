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

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ops'


OPS_LINKED_DATA_CACHE_URL = "http://ops2.few.vu.nl"
CHEMSPIDER_TOKEN = ""

raise "No OPS Linked Data Cache Url defined" if OPS_LINKED_DATA_CACHE_URL.empty?
raise "No ChemSpider Token defined" if CHEMSPIDER_TOKEN.empty?



#OPS.log = false



json_chemspider_client = OPS::JsonChemspiderClient.new

json_chemspider_client.exact_structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
json_chemspider_client.exact_structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :result_type => :compounds)
json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3))
json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3), :result_type => :compounds)
json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3), :threshold => 0.95)



soap_chemspider_client = OPS::SoapChemspiderClient.new(CHEMSPIDER_TOKEN)

soap_chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
soap_chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_tautomers)
soap_chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_including_h)
soap_chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :same_skeleton_excluding_h)
soap_chemspider_client.structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :match_type => :all_isomers)
# Note: Takes some time
soap_chemspider_client.substructure_search(%(O=C(O)c2c(OCCN1C(=O)\\C=C/C1=O)cccc2))
# Note: Takes some time
soap_chemspider_client.similarity_search(%(CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl))



linked_data_cache_client = OPS::LinkedDataCacheClient.new(OPS_LINKED_DATA_CACHE_URL)

linked_data_cache_client.compound_info("http://rdf.chemspider.com/187440")
# Note: Takes some time
linked_data_cache_client.compound_pharmacology("http://rdf.chemspider.com/187440")
# Note: Takes some time
linked_data_cache_client.compound_targets("http://rdf.chemspider.com/187440")