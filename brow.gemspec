# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "brow/version"

Gem::Specification.new do |s|
  s.name        = "brow"
  s.version     = Brow::VERSION
  s.authors     = ["Simen Svale Skogsrud"]
  s.email       = ["simen@bengler.no"]
  s.homepage    = ""
  s.summary     = %q{Brow is not Pow}
  s.description = %q{An autoconfigurator that works almost like Pow but uses unicorns and nginx}

  s.rubyforge_project = "brow"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_dependency "thor"
  s.add_dependency "rb-fsevent"
  s.add_dependency "guard"
  s.add_dependency "rake"
end
