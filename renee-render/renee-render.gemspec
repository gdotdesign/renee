# -*- encoding: utf-8 -*-
$:.push File.expand_path("../../renee-core/lib", __FILE__)
require "renee_core/version"

Gem::Specification.new do |s|
  s.name        = "renee-render"
  s.version     = Renee::Core::VERSION
  s.authors     = ["Josh Hull", "Nathan Esquenazi", "Arthur Chiu"]
  s.email       = ["joshbuddy@gmail.com", "nesquena@gmail.com", "mr.arthur.chiu@gmail.com"]
  s.homepage    = "http://reneerb.com"
  s.summary     = %q{The super-friendly web framework rendering component}
  s.description = %q{The super-friendly web framework rendering component.}

  s.rubyforge_project = "renee"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rack', "~> 1.3.0"
  s.add_runtime_dependency 'tilt', "~> 1.3.3"
  s.add_runtime_dependency 'callsite', '~> 0.0.6'
  s.add_runtime_dependency 'renee-core', "= #{Renee::Core::VERSION}"
  s.add_development_dependency 'minitest', "~> 2.6.1"
  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler'
  s.add_development_dependency "rack-test", ">= 0.5.0"
  s.add_development_dependency "haml", ">= 2.2.0"
end
