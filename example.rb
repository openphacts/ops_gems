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


OPS_API_URL = ENV['OPS_url']
OPS_APP_ID = ENV['OPS_app_id']
OPS_APP_KEY = ENV['OPS_app_key']
CS_API_URL = ENV['CS_url']

raise "No OPS API URL defined" if OPS_API_URL.nil? or OPS_API_URL.empty?
raise "No OPS APP ID defined" if OPS_APP_ID.nil? or OPS_APP_ID.empty?
raise "No OPS APP KEY defined" if OPS_APP_KEY.nil? or OPS_APP_KEY.empty?

#OPS.log = false



ops_client = OPS::OpenPhactsClient.new({
  :url => OPS_API_URL,
  :app_id => OPS_APP_ID,
  :app_key => OPS_APP_KEY
})

ops_client.smiles_to_url(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))

ops_client.compound_info("http://rdf.chemspider.com/187440")
ops_client.compound_pharmacology_count("http://rdf.chemspider.com/187440")
ops_client.compound_pharmacology("http://rdf.chemspider.com/187440")

ops_client.target_info("http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291")
ops_client.target_pharmacology_count("http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291")
ops_client.target_pharmacology("http://www.conceptwiki.org/concept/00059958-a045-4581-9dc5-e5a08bb0c291")



json_chemspider_client = OPS::JsonChemspiderClient.new(CS_API_URL)

json_chemspider_client.exact_structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1))
json_chemspider_client.exact_structure_search(%([O-]C(=O)[C@@H](NC(=O)C[NH3+])Cc1ccc(O)cc1), :result_type => :compounds)

json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3))
json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3), :result_type => :compounds)
json_chemspider_client.similarity_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3), :threshold => 0.95)

json_chemspider_client.substructure_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3))
json_chemspider_client.substructure_search(%(O=C1N(C(=O)c2c(cccc2)1)C3C(=O)NCCC3), :match_tautomers => true)