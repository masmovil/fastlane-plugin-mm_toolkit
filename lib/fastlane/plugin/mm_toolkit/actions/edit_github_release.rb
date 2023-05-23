# frozen_string_literal: true

module Fastlane
  module Actions
    class EditGithubReleaseAction < Action
      def self.run(params)
        require "fileutils"

        repository_name = params.fetch(:repository_name)
        server_url = params.fetch(:server_url)

        api_token = params[:api_token]
        api_bearer = params[:api_bearer]

        tag_name = params.fetch(:tag_name)

        release_name = params[:release_name]
        release_notes = params.fetch(:release_notes)
        mark_as_release = params.fetch(:mark_as_release)
        mark_as_latest_release = params.fetch(:mark_as_latest_release)

        edit_github_release(
          api_token,
          api_bearer,
          server_url,
          repository_name,
          tag_name,
          release_notes,
          release_name,
          mark_as_release,
          mark_as_latest_release,
        )
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.edit_github_release(
        api_token,
        api_bearer,
        server_url,
        repository_name,
        tag_name,
        release_notes,
        release_name,
        mark_as_release,
        mark_as_latest_release
      )
        release = get_release_by_tag_name(api_token, api_bearer, server_url, repository_name, tag_name)

        release_id = release["id"]
        release_data = {}
        release_data["name"] = release_name unless release_name.nil?
        release_data["body"] = release_notes
        (release_data["prerelease"] = false) if mark_as_release || mark_as_latest_release
        (release_data["make_latest"] = true) if mark_as_latest_release

        compose_edit_github_release(api_token, api_bearer, server_url, repository_name, release_id, release_data)
      end

      def self.get_release_by_tag_name(api_token, api_bearer, server_url, repository_name, tag_name)
        UI.important("Trying to get release with tag name #{tag_name} of repository #{repository_name}...")

        release = nil

        GithubApiAction.run(
          server_url: server_url,
          api_token: api_token,
          api_bearer: api_bearer,
          http_method: "GET",
          path: "repos/#{repository_name}/releases/tags/#{tag_name}",
          error_handlers: {
            "*" => proc do |result|
              UI.error("GitHub responded with #{result[:status]}:#{result[:body]}")
              UI.user_error!("Failed to retrieve release for tag name #{tag_name} on repository #{repository_name} from GitHub.")
            end,
          },
        ) do |result|
          UI.success("Successfully retrieved release for for tag name #{tag_name} on repository #{repository_name}!")
          release = result[:json]
        end

        release
      end

      def self.compose_edit_github_release(api_token, api_bearer, server_url, repository_name, release_id, release_data)
        UI.important("Trying to edit release notes of release ID #{release_id} on repository #{repository_name}...")

        GithubApiAction.run(
          server_url: server_url,
          api_token: api_token,
          api_bearer: api_bearer,
          http_method: "PATCH",
          path: "repos/#{repository_name}/releases/#{release_id}",
          body: release_data,
          error_handlers: {
            "*" => proc do |result|
              UI.error("GitHub responded with #{result[:status]}:#{result[:body]}")
              UI.user_error!("Failed to edit release for release ID #{release_id} on repository #{repository_name} from GitHub.")
            end,
          },
        ) do |_result|
          UI.success("Successfully edited release with release ID #{release_id} on repository #{repository_name}!")
        end
      end
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Edits a release note of an existing GitHub repository"
      end

      def self.details
        "The action edits a release note of an existing GitHub repository given a tag name"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :repository_name,
            env_name: "FL_EDIT_GITHUB_RELEASE_REPOSITORY_NAME",
            description: "The path to your repo, e.g. 'fastlane/fastlane'",
            verify_block: proc do |value|
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.include?("github.com")
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.split("/").count != 2
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :server_url,
            env_name: "FL_EDIT_GITHUB_RELEASE_SERVER_URL",
            description: "The server url. e.g. 'https://your.github.server/api/v3' (Default: 'https://api.github.com')",
            default_value: "https://api.github.com",
            optional: true,
            verify_block: proc do |value|
                            UI.user_error!("Include the protocol in the server url, e.g. "\
                              "https://your.github.server") unless value.include?("//")
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            env_name: "FL_EDIT_GITHUB_RELEASE_API_TOKEN",
            sensitive: true,
            code_gen_sensitive: true,
            default_value: ENV["GITHUB_API_TOKEN"],
            default_value_dynamic: true,
            description: "GitHub Personal Token (required for private repositories)",
            conflicting_options: [:api_bearer],
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_bearer,
            env_name: "FL_EDIT_GITHUB_RELEASE_API_BEARER",
            sensitive: true,
            code_gen_sensitive: true,
            description: "Use a Bearer authorization token. Usually generated by Github Apps, e.g. GitHub Actions GITHUB_TOKEN environment"\
              " variable",
            conflicting_options: [:api_token],
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :tag_name,
            env_name: "FL_EDIT_GITHUB_RELEASE_TAG_NAME",
            description: "The tag name to identigfy the release note to edit",
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_name,
            env_name: "FL_EDIT_GITHUB_RELEASE_RELEASE_NAME",
            description: "The release name that you want to set when editing the release",
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :release_notes,
            env_name: "FL_EDIT_GITHUB_RELEASE_RELEASE_NOTES",
            description: "The release notes that you want to set when editing the release",
          ),
          FastlaneCore::ConfigItem.new(
            key: :mark_as_release,
            env_name: "FL_EDIT_GITHUB_RELEASE_MARK_AS_RELEASED",
            description: "Whether or not mark the release as full release",
            type: Boolean,
            optional: true,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :mark_as_latest_release,
            env_name: "FL_EDIT_GITHUB_RELEASE_MARK_AS_LATEST_RELEASE",
            description: "Whether or not mark the release as latest release",
            type: Boolean,
            optional: true,
            default_value: false,
          ),
        ]
      end

      def self.authors
        ["adriangl"]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end

      def self.category
        # Check https://github.com/fastlane/fastlane/blob/0d1aa50045d57975d8b9e5d5f1f489d82ee0f437/fastlane/lib/fastlane/action.rb#L6
        # for available categories
        :source_control
      end
    end
  end
end
