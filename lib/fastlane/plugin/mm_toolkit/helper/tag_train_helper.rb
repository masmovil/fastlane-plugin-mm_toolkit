# frozen_string_literal: true

module Fastlane
  module Actions
    # Returns the latest tag from the current branch
    def self.get_latest_tag_from_branch
      sh("git describe --tags --abbrev=0").strip
    rescue
      nil
    end

    # Returns the latest version from the current branch
    def self.get_latest_version_from_branch
      tag = get_latest_tag_from_branch
      version = tag.gsub(/v/, "")

      version
    end
  end
end
