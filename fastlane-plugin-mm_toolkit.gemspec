# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastlane/plugin/mm_toolkit/version"

Gem::Specification.new do |spec|
  spec.name          = "fastlane-plugin-mm_toolkit"
  spec.version       = Fastlane::MmToolkit::VERSION
  spec.authors       = ["Sebastián Varela", "Adrián García"]
  spec.email         = ["sebastian.varela@masmovil.com", "adrian.garcia@masmovil.com"]

  spec.summary       = "MM ToolKit"
  spec.homepage      = "https://github.com/masmovil/fastlane-plugin-mm_toolkit"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_dependency("redcarpet", ">= 3.5.1")

  spec.add_development_dependency("pry")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rspec")
  spec.add_development_dependency("rspec_junit_formatter")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("rubocop", "~> 1.9")
  spec.add_development_dependency("rubocop-require_tools")
  spec.add_development_dependency("rubocop-shopify")
  spec.add_development_dependency("simplecov")
  spec.add_development_dependency("fastlane", ">= 2.172.0")
end
