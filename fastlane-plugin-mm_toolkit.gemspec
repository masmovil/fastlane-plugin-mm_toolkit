# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastlane/plugin/mm_toolkit/version"

Gem::Specification.new do |spec|
  spec.name          = "fastlane-plugin-mm_toolkit"
  spec.version       = Fastlane::MmToolkit::VERSION
  spec.authors       = ["Sebastián Varela", "Adrián García", "Raúl Pedraza"]
  spec.email         = ["sebastian.varela@masmovil.com", "adrian.garcia@masmovil.com", "raul.pedraza@masmovil.com"]

  spec.summary       = "MM ToolKit"
  spec.homepage      = "https://github.com/masmovil/fastlane-plugin-mm_toolkit"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["lib/**/*"] + ["README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_dependency("addressable", ">= 2.8.0")
  spec.add_dependency("csv")
  spec.add_dependency("down")
  spec.add_dependency("google-cloud-bigquery")
  spec.add_dependency("httparty", "~> 0.21.0")
  spec.add_dependency("redcarpet", ">= 3.5.1")

  spec.add_development_dependency("danger")
  spec.add_development_dependency("danger-rubocop")
  spec.add_development_dependency("fastlane")
  spec.add_development_dependency("pry")
  spec.add_development_dependency("rubocop")
  spec.add_development_dependency("rubocop-shopify")
end
