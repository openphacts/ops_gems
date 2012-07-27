require 'rubygems'
require 'bundler/setup'

require 'benchmark'
require 'webmock'

WebMock.disable_net_connect!

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ops'

OPS.log = false


#
## Stub Linked Data Cache API
#

WebMock::API.stub_request(:get, "http://ops.few.vu.nl/compound.json?uri=http://known.com/1111").
  to_return(:body => %({"format":"linked-data-api","version":"0.2","result":{"_about":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Fknown.com%2F1111","definition":"http://ops.few.vu.nl/api-config","extendedMetadataVersion":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Fknown.com%2F1111&_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite","primaryTopic":{"_about":"http://known.com/1111","inchi":"InChI=1S/C21H16ClF3N4O3/c1-26-19(30)18-11-15(8-9-27-18)32-14-5-2-12(3-6-14)28-20(31)29-13-4-7-17(22)16(10-13)21(23,24)25/h2-11H,1H3,(H,26,30)(H2,28,29,31)","inchikey":"MLDQJTXFUGDVEO-UHFFFAOYSA-N","smiles":"CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl","inDataset":"http://www.chemspider.com","exactMatch":[{"_about":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","alogp":4.175,"full_mwt":464.825,"hba":4,"hbd":3,"molform":"C21H16ClF3N4O3","mw_freebase":464.825,"psa":92.35,"rtb":6,"inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398","inDataset":"http://linkedlifedata.com/resource/drugbank","biotransformation":"Sorafenib
is metabolized primarily in the liver, undergoing oxidative metabolism, mediated
by CYP3A4, as well as glucuronidation mediated by UGT1A9. Sorafenib accounts
for approximately 70-85% of the circulating analytes in plasma at steady-
state. Eight metabolites of sorafenib have been identified, of which five
have been detected in plasma. The main circulating metabolite of sorafenib
in plasma, the pyridine N-oxide, shows <i>in vitro</i> potency similar to
that of sorafenib. This metabolite comprises approximately 9-16% of circulating
analytes at steady-state.","description":"Sorafenib (rINN), marketed as Nexavar
by Bayer, is a drug approved for the treatment of advanced renal cell carcinoma
(primary kidney cancer). It has also received \\"Fast Track\\" designation by
the FDA for the treatment of advanced hepatocellular carcinoma (primary liver
cancer), and has since performed well in Phase III trials.\nSorafenib is a
small molecular inhibitor of Raf kinase, PDGF (platelet-derived growth factor),
VEGF receptor 2 & 3 kinases and c Kit the receptor for Stem cell factor. A
growing number of drugs target most of these pathways. The originality of
Sorafenib lays in its simultaneous targeting of the Raf/Mek/Erk pathway.","proteinBinding":"99.5%","toxicity":"The
highest dose of sorafenib studied clinically is 800 mg twice daily. The adverse
reactions observed at this dose were primarily diarrhea and dermatologic events.
No information is available on symptoms of acute overdose in animals because
of the saturation of absorption in oral acute toxicity studies conducted in
animals."},"http://known.com/1111",{"_about":"http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5","inDataset":"http://www.conceptwiki.org","prefLabel":"Sorafenib"}],"isPrimaryTopicOf":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Fknown.com%2F1111"}}}),
            :headers => {"Content-Type"=>"application/json; charset=utf-8"})
WebMock::API.stub_request(:get, "http://ops.few.vu.nl/compound.json?uri=http://unknown.com/0000").
  to_return(:body => %({"format":"linked-data-api","version":"0.2","result":{"_about":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Funknown.com%2F1111","definition":"http://ops.few.vu.nl/api-config","extendedMetadataVersion":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Funknown.com%2F1111&_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite","primaryTopic":{"_about":"http://unknown.com/1111","isPrimaryTopicOf":"http://ops.few.vu.nl/compound.json?uri=http%3A%2F%2Funknown.com%2F1111"}}}),
            :headers => {"Content-Type"=>"application/json; charset=utf-8"})
WebMock::API.stub_request(:get, "http://ops.few.vu.nl/compound/pharmacology.json?uri=http://known.com/1111").
  to_return(:body => %({"format":"linked-data-api","version":"0.2","result":{"_about":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Fknown.com%2F1111","definition":"http://ops.few.vu.nl/api-config","extendedMetadataVersion":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Fknown.com%2F1111&_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite","primaryTopic":{"_about":"http://known.com/1111","inchi":"InChI=1S/C21H16ClF3N4O3/c1-26-19(30)18-11-15(8-9-27-18)32-14-5-2-12(3-6-14)28-20(31)29-13-4-7-17(22)16(10-13)21(23,24)25/h2-11H,1H3,(H,26,30)(H2,28,29,31)","inchikey":"MLDQJTXFUGDVEO-UHFFFAOYSA-N","smiles":"CNC(=O)c1cc(ccn1)Oc2ccc(cc2)NC(=O)Nc3ccc(c(c3)C(F)(F)F)Cl","inDataset":"http://www.chemspider.com","exactMatch":["http://known.com/1111",{"_about":"http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00398","inDataset":"http://linkedlifedata.com/resource/drugbank","drugType":"approved","genericName":"Sorafenib"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","full_mwt":464.825,"inDataset":"http://data.kasabi.com/dataset/chembl-rdf","activity":[{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1650177","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1650168","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a325048","target":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t30003","title":"Serine/threonine-protein
kinase PLK4","assay_organism":"Homo sapiens"},"assay_organism":"Homo sapiens"},"relation":"=","standardUnits":"nM","standardValue":3400,"activity_type":"Kd","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1650015","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a325057","target":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t12947","title":"Cyclin-dependent
kinase 5","assay_organism":"Homo sapiens"},"assay_organism":"Homo sapiens"},"relation":"=","standardUnits":"nM","standardValue":6200,"activity_type":"Kd","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1650114","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a325017","target":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t30037","title":"MAP
kinase signal-integrating kinase 2","assay_organism":"Homo sapiens"},"assay_organism":"Homo
sapiens"},"relation":"=","standardUnits":"nM","standardValue":250,"activity_type":"Kd","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1650150","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a325031","target":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t30020","title":"Ephrin
type-B receptor 1","assay_organism":"Homo sapiens"},"assay_organism":"Homo
sapiens"},"relation":"=","standardUnits":"nM","standardValue":1700,"activity_type":"Kd","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1442151","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a311891","target":[{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t11409","title":"Dual
specificity mitogen-activated protein kinase kinase 1","assay_organism":"Homo
sapiens"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t10904","title":"Serine/threonine-protein
kinase RAF","assay_organism":"Homo sapiens"}],"assay_organism":"Homo sapiens"},"relation":"=","standardUnits":"nM","standardValue":3300,"activity_type":"IC50","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"},{"_about":"http://data.kasabi.com/dataset/chembl-rdf/activity/a1442152","forMolecule":"http://data.kasabi.com/dataset/chembl-rdf/molecule/m276734","onAssay":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/assay/a311323","target":{"_about":"http://data.kasabi.com/dataset/chembl-rdf/target/t80928","title":"HCT-116
(Colon carcinoma cells)","assay_organism":"Homo sapiens"},"assay_organism":"Homo
sapiens"},"relation":"=","standardUnits":"uM","standardValue":5.4,"activity_type":"GI50","inDataset":"http://data.kasabi.com/dataset/chembl-rdf"}]},{"_about":"http://www.conceptwiki.org/concept/38932552-111f-4a4e-a46a-4ed1d7bdf9d5","inDataset":"http://www.conceptwiki.org","prefLabel":"Sorafenib"}],"isPrimaryTopicOf":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Fknown.com%2F1111"}}}),
            :headers => {"Content-Type"=>"application/json; charset=utf-8"})
WebMock::API.stub_request(:get, "http://ops.few.vu.nl/compound/pharmacology.json?uri=http://unknown.com/0000").
  to_return(:body => %({"format":"linked-data-api","version":"0.2","result":{"_about":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Funknown.com%2F1111","definition":"http://ops.few.vu.nl/api-config","extendedMetadataVersion":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Funknown.com%2F1111&_metadata=all%2Cviews%2Cformats%2Cexecution%2Cbindings%2Csite","primaryTopic":{"_about":"http://unknown.com/1111","isPrimaryTopicOf":"http://ops.few.vu.nl/compound/pharmacology.json?uri=http%3A%2F%2Funknown.com%2F1111"}}}),
            :headers => {"Content-Type"=>"application/json; charset=utf-8"})



#
## Run Benchmarks
#

ldc_client = OPS::LinkedDataCacheClient.new('http://ops.few.vu.nl')

n = 1000

Benchmark.bmbm do |x|
  x.report("compound_info with know compound") do
    n.times do
      ldc_client.compound_info("http://known.com/1111")
    end
  end
  x.report("compound_info with unknown compound") do
    n.times do
      ldc_client.compound_info("http://unknown.com/0000")
    end
  end
  x.report("compound_pharmacology with know compound") do
    n.times do
      ldc_client.compound_pharmacology_info("http://known.com/1111")
    end
  end
  x.report("compound_pharmacology with unknown compound") do
    n.times do
      ldc_client.compound_pharmacology_info("http://unknown.com/0000")
    end
  end
end


#Thomass-MacBook-Pro:ops_gems tmak$ ruby benchmark.rb
#Rehearsal -------------------------------------------------------------------------------
#compound_info with know compound              1.810000   0.030000   1.840000 (  1.829274)
#compound_info with unknown compound           1.130000   0.010000   1.140000 (  1.148932)
#compound_pharmacology with know compound      1.720000   0.030000   1.750000 (  1.742556)
#compound_pharmacology with unknown compound   1.040000   0.010000   1.050000 (  1.051695)
#---------------------------------------------------------------------- total: 5.780000sec
#
#                                                  user     system      total        real
#compound_info with know compound              1.800000   0.020000   1.820000 (  1.823159)
#compound_info with unknown compound           1.110000   0.010000   1.120000 (  1.122017)
#compound_pharmacology with know compound      1.700000   0.020000   1.720000 (  1.721803)
#compound_pharmacology with unknown compound   1.050000   0.020000   1.070000 (  1.055116)
#Thomass-MacBook-Pro:ops_gems tmak$ ruby benchmark.rb
#Rehearsal -------------------------------------------------------------------------------
#compound_info with know compound              1.840000   0.030000   1.870000 (  1.873038)
#compound_info with unknown compound           1.140000   0.010000   1.150000 (  1.147239)
#compound_pharmacology with know compound      1.710000   0.030000   1.740000 (  1.735416)
#compound_pharmacology with unknown compound   1.050000   0.010000   1.060000 (  1.067197)
#---------------------------------------------------------------------- total: 5.820000sec
#
#                                                  user     system      total        real
#compound_info with know compound              1.850000   0.020000   1.870000 (  1.877739)
#compound_info with unknown compound           1.120000   0.010000   1.130000 (  1.131437)
#compound_pharmacology with know compound      1.710000   0.030000   1.740000 (  1.731620)
#compound_pharmacology with unknown compound   1.060000   0.010000   1.070000 (  1.068418)
