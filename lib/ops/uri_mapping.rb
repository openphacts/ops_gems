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


module OPS
  class URIMapping
    MAPPINGS = [
      [/http:\/\/rdf\.chemspider\.com\/(\d+)/, "http://www.chemspider.com/Chemical-Structure.%s.html"],
      [/http:\/\/www4\.wiwiss\.fu-berlin\.de\/drugbank\/resource\/drugs\/([\w\d]+)/, "http://www4.wiwiss.fu-berlin.de/drugbank/page/drugs/%s"],
      [/http:\/\/wifo.*\.informatik\.uni-mannheim\.de\/drugbank\/page\/drugs\/(DB\d+)/, "http://www.drugbank.ca/drugs/%s"],
      [/http:\/\/data\.kasabi\.com\/dataset\/chembl-rdf\/chemblid\/(CHEMBL\d+)/, "https://www.ebi.ac.uk/chembldb/compound/inspect/%s"],
      [/http:\/\/data\.kasabi\.com\/dataset\/chembl-rdf\/(chemblid|molecule|target|activity|assay)\/([\w\d]+)/, "http://linkedchemistry.info/chembl/%s/%s"],
      [/http:\/\/www\.conceptwiki\.org\/concept\/([\w\d\-]+)/, "http://www.conceptwiki.org/wiki/#/concept/%s/view"],
    ].freeze

    def resolve_uri(uri)
      MAPPINGS.each do |regex, href_pattern|
        match = regex.match(uri)
        return href_pattern % match[1..-1] if match
      end

      nil
    end
  end
end