# frozen_string_literal: true

require 'date'

module Fastlane
  module Actions
    module SharedValues
      TAG_TRAIN_API_NEW_TAG_CREATED = :TAG_TRAIN_API_NEW_TAG_CREATED
      TAG_TRAIN_API_LATEST_VERSION = :TAG_TRAIN_API_LATEST_VERSION
      TAG_TRAIN_API_LATEST_TAG = :TAG_TRAIN_API_LATEST_TAG
      TAG_TRAIN_API_COMMIT_COUNT = :TAG_TRAIN_API_COMMIT_COUNT
      TAG_TRAIN_API_YEAR = :TAG_TRAIN_API_YEAR
      TAG_TRAIN_API_WEEK_OF_YEAR = :TAG_TRAIN_API_WEEK_OF_YEAR
    end

    class TagTrainApiAction < Action
      def self.run(params)
        github_token = params.fetch(:github_token)
        github_repository = params.fetch(:github_repository)
        branch = params.fetch(:branch)
        committer_name = params.fetch(:committer_name)
        committer_email = params.fetch(:committer_email)
        reference_date = Date.parse(params.fetch(:reference_date))

        UI.message("Reading current tags...")
        latest_version = get_version_from_latest_git_tag_from_branch
        head_tag = get_head_tag_from_git
        week_data = get_week_data(reference_date)
        weekly_version = get_weekly_version(reference_date)

        new_tag_created = false
        latest_tag = ""
        output_year = nil
        output_week_of_year = nil

        UI.header("Tag analysis")
        if !head_tag.empty?
          latest_tag = head_tag
          UI.important("HEAD is already tagged as #{head_tag}, no new tag is needed")
        elsif Gem::Version.new(latest_version) < Gem::Version.new(weekly_version)
          new_tag_created = true
          latest_tag = weekly_version
          latest_version = weekly_version
          output_year = week_data[:year].to_i
          output_week_of_year = week_data[:week_of_year].to_i

          UI.message("Creating signed commit and annotated tag via GitHub API...")
          create_signed_commit_and_tag(
            github_token: github_token,
            github_repository: github_repository,
            branch: branch,
            committer_name: committer_name,
            committer_email: committer_email,
            tag: latest_tag,
            week_number: output_week_of_year,
          )
          UI.success("New tag #{latest_tag} created and pushed!")
        else
          latest_tag = latest_version
          UI.important("No new tag is needed, we are on the correct train 🚂")
        end

        commit_count = other_action.number_of_commits

        UI.success("Using #{latest_tag} (#{commit_count})")

        Actions.lane_context[SharedValues::TAG_TRAIN_API_NEW_TAG_CREATED] = new_tag_created
        Actions.lane_context[SharedValues::TAG_TRAIN_API_LATEST_VERSION] = latest_version
        Actions.lane_context[SharedValues::TAG_TRAIN_API_LATEST_TAG] = latest_tag
        Actions.lane_context[SharedValues::TAG_TRAIN_API_COMMIT_COUNT] = commit_count
        Actions.lane_context[SharedValues::TAG_TRAIN_API_YEAR] = output_year
        Actions.lane_context[SharedValues::TAG_TRAIN_API_WEEK_OF_YEAR] = output_week_of_year

        {
          new_tag_created: new_tag_created,
          latest_version: latest_version,
          commit_count: commit_count,
          year: output_year,
          week_of_year: output_week_of_year,
        }
      end

      #####################################################
      # @!group GitHub API operations
      #####################################################

      def self.create_signed_commit_and_tag(github_token:, github_repository:, branch:, tag:, week_number:, committer_name: nil, committer_email: nil)
        message = "Happy week #{week_number}!"
        identity = if committer_name && committer_email
          { name: committer_name, email: committer_email, date: Time.now.utc.iso8601 }
        end

        # Step 1: resolve current HEAD SHA for the branch
        head_sha = gh_get(github_token, "/repos/#{github_repository}/git/ref/heads/#{branch}")["object"]["sha"]
        UI.message("Current HEAD: #{head_sha}")

        # Step 2: get the tree SHA from that commit (required to produce an empty commit on the same tree)
        tree_sha = gh_get(github_token, "/repos/#{github_repository}/git/commits/#{head_sha}")["tree"]["sha"]
        UI.message("Current tree: #{tree_sha}")

        # Step 3: create an empty commit — GitHub marks it as Verified automatically
        new_commit_sha = gh_post(github_token, "/repos/#{github_repository}/git/commits", {
          message: message,
          tree: tree_sha,
          parents: [head_sha],
          author: identity,
          committer: identity,
        }.compact)["sha"]
        UI.message("Created signed commit: #{new_commit_sha}")

        # Step 4: fast-forward the branch ref to the new commit
        gh_patch(github_token, "/repos/#{github_repository}/git/refs/heads/#{branch}", {
          sha: new_commit_sha,
        })
        UI.message("Branch #{branch} updated to #{new_commit_sha}")

        # Step 5: create an annotated tag object — GitHub also marks this as Verified
        tag_object_sha = gh_post(github_token, "/repos/#{github_repository}/git/tags", {
          tag: tag,
          message: message,
          object: new_commit_sha,
          type: "commit",
          tagger: identity,
        }.compact)["sha"]
        UI.message("Created signed tag object: #{tag_object_sha}")

        # Step 6: create the tag ref pointing to the annotated tag object (not the commit)
        gh_post(github_token, "/repos/#{github_repository}/git/refs", {
          ref: "refs/tags/#{tag}",
          sha: tag_object_sha,
        })
        UI.message("Tag ref refs/tags/#{tag} created")
      end

      #####################################################
      # @!group github_api wrappers
      #####################################################

      def self.gh_get(token, path)
        other_action.github_api(
          api_token: token,
          http_method: "GET",
          path: path,
        )[:json]
      end

      def self.gh_post(token, path, body)
        other_action.github_api(
          api_token: token,
          http_method: "POST",
          path: path,
          body: body,
        )[:json]
      end

      def self.gh_patch(token, path, body)
        other_action.github_api(
          api_token: token,
          http_method: "PATCH",
          path: path,
          body: body,
        )[:json]
      end

      #####################################################
      # @!group Version / tag helpers
      #####################################################

      def self.get_week_data(reference_date)
        {
          year: reference_date.strftime("%g").to_i,
          week_of_year: reference_date.strftime("%V").to_i,
        }
      end

      def self.get_weekly_version(reference_date)
        data = get_week_data(reference_date)
        "#{data[:year]}.#{data[:week_of_year]}.0"
      end

      def self.get_version_from_latest_git_tag_from_branch
        Actions.get_latest_tag_from_branch
      end

      def self.get_head_tag_from_git
        sh("git tag --contains HEAD", log: false).strip
      rescue StandardError
        ""
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate weekly-based tags using the GitHub API, producing GPG-verified commits and tags"
      end

      def self.details
        "Replicates the tag_train logic (CalVer YY.WW.0, ISO-8601 weeks) but creates the " \
          "empty commit and annotated tag via the GitHub Git Data API instead of local git commands. " \
          "Commits and annotated tags created through the API are automatically marked as Verified " \
          "by GitHub, satisfying organizations that require signed commits without a local GPG key."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :github_token,
            env_name: "FL_TAG_TRAIN_API_GITHUB_TOKEN",
            description: "GitHub App installation token or PAT with contents:write permission",
            type: String,
            optional: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :github_repository,
            env_name: "FL_TAG_TRAIN_API_GITHUB_REPOSITORY",
            description: "GitHub repository in owner/repo format (e.g. 'myorg/myrepo')",
            type: String,
            optional: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :branch,
            env_name: "FL_TAG_TRAIN_API_BRANCH",
            description: "Branch to commit to (e.g. 'develop')",
            type: String,
            optional: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :committer_name,
            env_name: "FL_TAG_TRAIN_API_COMMITTER_NAME",
            description: "Name of the committer/tagger. If omitted, GitHub uses the token's identity",
            type: String,
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :committer_email,
            env_name: "FL_TAG_TRAIN_API_COMMITTER_EMAIL",
            description: "Email of the committer/tagger. If omitted, GitHub uses the token's identity",
            type: String,
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :reference_date,
            env_name: "FL_TAG_TRAIN_API_REFERENCE_DATE",
            description: "Reference date for the tag in YYYY-MM-DD format. Defaults to next week's date",
            type: String,
            optional: true,
            default_value: (Time.now + (60 * 60 * 24 * 7)).strftime("%F"),
          ),
        ]
      end

      def self.output
        [
          ["TAG_TRAIN_API_NEW_TAG_CREATED", "True if a new tag was created this run"],
          ["TAG_TRAIN_API_LATEST_VERSION", "App version inferred from the current tag"],
          ["TAG_TRAIN_API_LATEST_TAG", "The latest tag (new or existing)"],
          ["TAG_TRAIN_API_COMMIT_COUNT", "Total commit count on the current branch"],
          ["TAG_TRAIN_API_YEAR", "Two-digit year used in the new weekly tag (nil if no new tag)"],
          ["TAG_TRAIN_API_WEEK_OF_YEAR", "ISO-8601 week number used in the new weekly tag (nil if no new tag)"],
        ]
      end

      def self.return_type
        :hash
      end

      def self.return_value
        "Hash with :new_tag_created, :latest_version, :commit_count, :year, and :week_of_year. " \
          ":year and :week_of_year are nil when no new tag was created."
      end

      def self.authors
        ["sebastianvarela", "adriangl"]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end

      def self.category
        :source_control
      end
    end
  end
end
