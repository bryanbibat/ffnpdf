# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ffnpdf/version"

Gem::Specification.new do |s|
  s.name        = "ffnpdf"
  s.version     = Ffnpdf::VERSION
  s.authors     = ["Bryan Bibat"]
  s.email       = ["bry@bryanbibat.net"]
  s.homepage    = ""
  s.summary     = %q{PDF generator for FF.net stories}
  s.description = %q{Scrapes a story off FF.net, converts it to Markdown, and turns it to PDF with LaTeX}

  s.rubyforge_project = "ffnpdf"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "test_notifier"
  s.add_development_dependency "autotest"
  s.add_development_dependency "fakefs"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "httparty"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "httparty"
end
