$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "oojspec/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "oojspec"
  s.version     = Oojspec::VERSION
  s.authors     = ["Rodrigo Rosenfeld Rosas"]
  s.email       = ["rr.rosas@gmail.com"]
  s.homepage    = "http://github.com/rosenfeld/oojspec"
  s.summary     = "Object-oriented client-side testing"
  s.description = %q{ A test runner similar to RSpec for client-side code built
    on top of Buster.js that is more suited for integration tests.}

  s.files = Dir["{app,lib,vendor}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "coffee-rails"
  s.add_dependency "rails-sandbox-assets", ">= 0.1.0"
end
