# frozen_string_literal: true

source("https://rubygems.org")

gem("fastlane")
gem("danger")
gem("danger-rubocop")
gem("rubocop")
gem("rubocop-shopify")

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
