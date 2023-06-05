# frozen_string_literal: true

module Fastlane
  module Actions
    class UploadAssetsToGithubReleaseAction < Action
      def self.run(params)
        repository_name = params.fetch(:repository_name)
        server_url = params.fetch(:server_url)
        version = params.fetch(:version)
        assets = params.fetch(:upload_assets)

        api_token = params[:api_token]
        api_bearer = params[:api_bearer]

        upload_assets_to_release(api_token, api_bearer, server_url, repository_name, version, assets)
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.upload_assets_to_release(api_token, api_bearer, server_url, repository_name, version, assets)
        UI.important("Updating release of #{repository_name} on version #{version} with upload assets: #{assets}.")

        if api_token
          release = other_action.get_github_release(
            url: repository_name,
            server_url: server_url,
            api_token: api_token,
            version: version,
          )
        elsif api_bearer
          release = other_action.get_github_release(
            url: repository_name,
            server_url: server_url,
            api_bearer: api_bearer,
            version: version,
          )
        else
          UI.user_error!("You need to provide either an api_token or an api_bearer.")
        end

        UI.user_error!("No release with version #{version}. Review your API tokens, repository name and tag and try again.") unless release

        asset_upload_url_template = release["upload_url"]
        release_id = release["id"]
        html_url = release["html_url"]

        upload_assets(assets, asset_upload_url_template, api_token, api_bearer)

        # Fetch the release again, so that it contains the uploaded assets
        GithubApiAction.run(
          server_url: server_url,
          api_token: api_token,
          api_bearer: api_bearer,
          http_method: "GET",
          path: "repos/#{repository_name}/releases/#{release_id}",
          error_handlers: {
            "*" => proc do |get_result|
              UI.error("GitHub responded with #{get_result[:status]}:#{get_result[:body]}")
              UI.user_error!("Failed to fetch the newly created release, but it *has been created* successfully.")
            end,
          },
        ) do |get_result|
          UI.success("Successfully uploaded assets #{assets} to release \"#{html_url}\"")
          return get_result[:json]
        end
      end

      def self.upload_assets(assets, upload_url_template, api_token, api_bearer)
        assets.each do |asset|
          upload(asset, upload_url_template, api_token, api_bearer)
        end
      end

      def self.upload(asset_path, upload_url_template, api_token, api_bearer)
        # If it's a directory, zip it first in a temp directory, because we can only upload binary files
        absolute_path = File.absolute_path(asset_path)

        # Check that the asset even exists
        UI.user_error!("Asset #{absolute_path} doesn't exist") unless File.exist?(absolute_path)

        if File.directory?(absolute_path)
          Dir.mktmpdir do |dir|
            tmpzip = File.join(dir, File.basename(absolute_path) + ".zip")
            sh("cd \"#{File.dirname(absolute_path)}\"; zip -r --symlinks \"#{tmpzip}\" \"#{File.basename(absolute_path)}\" 2>&1 >/dev/null")
            upload_file(tmpzip, upload_url_template, api_token, api_bearer)
          end
        else
          upload_file(absolute_path, upload_url_template, api_token, api_bearer)
        end
      end

      def self.upload_file(file, url_template, api_token, api_bearer)
        require "addressable/template"
        file_name = File.basename(file)
        expanded_url = Addressable::Template.new(url_template).expand(name: file_name).to_s
        headers = { "Content-Type" => "application/zip" } # works for all binary files
        UI.important("Uploading #{file_name}")
        GithubApiAction.run(
          api_token: api_token,
          api_bearer: api_bearer,
          http_method: "POST",
          headers: headers,
          url: expanded_url,
          raw_body: File.read(file),
          error_handlers: {
            "*" => proc do |result|
              UI.error("GitHub responded with #{result[:status]}:#{result[:body]}")
              UI.user_error!("Failed to upload asset #{file_name} to GitHub.")
            end,
          },
        ) do |_result|
          UI.success("Successfully uploaded #{file_name}.")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload assets to an existing GitHub release"
      end

      def self.details
        "The action uploads given assets to an existing GitHub release.\n"\
          "The code is mostly based on `get_github_release` and `set_github_release` code, so check them out!"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :repository_name,
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_REPOSITORY_NAME",
            description: "The path to your repo, e.g. 'fastlane/fastlane'",
            verify_block: proc do |value|
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.include?("github.com")
                            UI.user_error!("Only pass the path, e.g. 'fastlane/fastlane'") if value.split("/").count != 2
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :server_url,
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_SERVER_URL",
            description: "The server url. e.g. 'https://your.github.server/api/v3' (Default: 'https://api.github.com')",
            default_value: "https://api.github.com",
            optional: true,
            verify_block: proc do |value|
                            UI.user_error!("Include the protocol in the server url, e.g. "\
                              "https://your.github.server") unless value.include?("//")
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_VERSION",
            description: "The version tag of the release to check",
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_token,
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_API_TOKEN",
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
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_API_BEARER",
            sensitive: true,
            code_gen_sensitive: true,
            description: "Use a Bearer authorization token. Usually generated by Github Apps, e.g. GitHub Actions GITHUB_TOKEN environment"\
              " variable",
            conflicting_options: [:api_token],
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :upload_assets,
            env_name: "FL_UPLOAD_TO_GITHUB_RELEASE_UPLOAD_ASSETS",
            description: "Path to assets to be uploaded with the release",
            type: Array,
            verify_block: proc do |value|
                            UI.user_error!("upload_assets must be an Array of paths to assets") unless value.is_a?(Array)
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
