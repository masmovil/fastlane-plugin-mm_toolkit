# frozen_string_literal: true

module Fastlane
  module Actions
    class DownloadGithubReleaseNotesAction < Action
      def self.run(params)
        require "fileutils"

        repository_name = params.fetch(:repository_name)
        server_url = params.fetch(:server_url)

        api_token = params[:api_token]
        api_bearer = params[:api_bearer]

        download_folder_path = params.fetch(:download_folder_path)
        releases_only = params.fetch(:releases_only)

        file_name_callback = params.fetch(:file_name_callback)

        download_release_notes(api_token, api_bearer, server_url, repository_name, download_folder_path, releases_only, file_name_callback)
      end

      #####################################################
      # @!group support functions
      #####################################################

      # rubocop:disable Metrics/ParameterLists
      def self.download_release_notes(api_token, api_bearer, server_url, repository_name, download_folder_path,
        releases_only, file_name_callback)
        UI.important("Downloading release notes of #{repository_name}")

        # Get all releases from the API
        releases = get_all_releases(api_token, api_bearer, server_url, repository_name)

        (releases = releases.select { |release| !release["prerelease"] }) if releases_only

        releases.collect do |release|
          release_body = release["body"]
          release_created_at = release["created_at"]

          release_file_name =  "#{file_name_callback.call(release)}.md"

          release_notes_path = File.join(download_folder_path, release_file_name)

          FileUtils.mkdir_p(download_folder_path)

          File.open(release_notes_path, "w") { |file| file << release_body }
          File.utime(Time.parse(release_created_at).to_time, Time.parse(release_created_at).to_time, release_notes_path)
        end

        UI.success("Succesfully downloaded #{releases.count} release note(s) from #{repository_name}!")
      end
      # rubocop:enable Metrics/ParameterLists

      def self.get_all_releases(api_token, api_bearer, server_url, repository_name)
        releases_result = []
        releases_page = 0
        releases_page_quantity = 100
        stop = false

        loop do
          UI.important("Downloading releases page #{releases_page}...")
          GithubApiAction.run(
            server_url: server_url,
            api_token: api_token,
            api_bearer: api_bearer,
            http_method: "GET",
            path: "repos/#{repository_name}/releases?per_page=#{releases_page_quantity}&page=#{releases_page}",
            error_handlers: {
              "*" => proc do |_get_result|
                stop = true
              end,
            },
          ) do |get_result|
            result_data = get_result[:json]
            if result_data.empty?
              stop = true
            end

            releases_result.concat(result_data)
            releases_page += 1
          end

          if stop
            break
          end
        end

        UI.success("Successfully retrieved releases from #{repository_name}")
        releases_result
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Downloads all release notes of an existing GitHub repository"
      end

      def self.details
        "The action downloads all available release notes from a given repository, saving them to a folder"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :repository_name,
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_REPOSITORY_NAME",
            description: "The path to your repo, e.g. 'fastlane/fastlane'",
            verify_block: proc do |value|
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.include?("github.com")
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.split("/").count != 2
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :server_url,
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_SERVER_URL",
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
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_API_TOKEN",
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
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_API_BEARER",
            sensitive: true,
            code_gen_sensitive: true,
            description: "Use a Bearer authorization token. Usually generated by Github Apps, e.g. GitHub Actions GITHUB_TOKEN environment"\
              " variable",
            conflicting_options: [:api_token],
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :download_folder_path,
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_DOWNLOAD_FOLDER_PATH",
            description: "The path where you want to download the release notes to",
          ),
          FastlaneCore::ConfigItem.new(
            key: :releases_only,
            env_name: "FL_DOWNLOAD_GITHUB_RELEASES_RELEASES_ONLY",
            description:
                          "Whether or not to only download release notes of releases marked as release",
            type: Boolean,
            optional: true,
            default_value: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :file_name_callback,
            description: "Use this block to change the release notes file name. The raw release object is passed as parameter. "\
              "The default is the name of the relase",
            optional: true,
            default_value: proc do |release|
                             release["name"]
                           end,
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
