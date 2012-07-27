
module OPS
  class URIMapping
    MAPPINGS = [
      [/http:\/\/rdf\.chemspider\.com\/(\d+)/, "http://www.chemspider.com/Chemical-Structure.%s.html"],
      [/http:\/\/www4\.wiwiss\.fu-berlin\.de\/drugbank\/resource\/drugs\/([\w\d]+)/, "http://www4.wiwiss.fu-berlin.de/drugbank/page/drugs/%s"],
      [/http:\/\/data\.kasabi\.com\/dataset\/chembl-rdf\/(molecule|target)\/([\w\d]+)/, "http://data.kasabi.com/dataset/chembl-rdf/%s/%s.html"],
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