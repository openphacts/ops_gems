# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'ops/version'

Gem::Specification.new do |s|
  s.name        = "ops"
  s.version     = OPS::VERSION
  s.authors     = "Thomas Marek"
  s.email       = "thomas.marek@biosolveit.de"
  s.homepage    = ""
  s.summary     = %q{Toolkit for the OPS Platform}
  s.description = %q{Toolkit for the OPS Platform}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_runtime_dependency "activesupport", "~> 3.2.0"
  s.add_runtime_dependency "rdf", "~> 0.3.7"
  s.add_runtime_dependency "nokogiri", "~> 1.5.5"
  s.add_runtime_dependency "httpclient", "~> 2.2.5"
  s.add_runtime_dependency "multi_json", "~> 1.3.6"
  s.add_runtime_dependency "oj", "~> 1.3.0"

  s.add_development_dependency "rake", "~> 0.9.2.2"
  s.add_development_dependency "rspec", "~> 2.11.0"
  s.add_development_dependency "webmock", "~> 1.8.7"
  s.add_development_dependency "vcr", "~> 2.2.3"
end