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
  s.add_runtime_dependency "nokogiri", "~> 1.5.5"
  s.add_runtime_dependency "httpclient", "~> 2.2.5"
  s.add_runtime_dependency "multi_json", "~> 1.3.6"
  s.add_runtime_dependency "oj", "~> 1.3.0"

  s.add_development_dependency "rake", "~> 0.9.2.2"
  s.add_development_dependency "rspec", "~> 2.11.0"
  s.add_development_dependency "webmock", "~> 1.8.7"
  s.add_development_dependency "vcr", "~> 2.2.3"
  s.add_development_dependency "flexmock", "~> 1.0.3"
  s.add_development_dependency "awesome_print"
end