# frozen_string_literal: true

require "uri"

module Fastlane
  module Helper
    class GithubUtilsHelper
      GITHUB_BASE_URL = "https://www.github.com"
      URL_REGEX = /\A#{URI.regexp(['http', 'https'])}\z/

      def self.compose_github_url(url)
        if url =~ URL_REGEX
          URI.parse(url)
        else
          URI.join(GITHUB_BASE_URL, url)
        end.to_s
      end
    end
  end
end
