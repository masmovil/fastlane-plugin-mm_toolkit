# frozen_string_literal: true

module Fastlane
  module Actions
    module SharedValues
      FL_CHANGELOG ||= :FL_CHANGELOG
    end

    class GitChangelogAction < Action
      def self.run(params)
        if params[:commits_count]
          UI.success("Collecting the last #{params[:commits_count]} Git commits")
        else
          if params[:between]
            if params[:between].is_a?(String) && params[:between].include?(",") # :between is string
              from, to = params[:between].split(",", 2)
            elsif params[:between].is_a?(Array)
              from, to = params[:between]
            end
          else
            from = get_latest_git_tag(params[:check_all_repo])
            UI.verbose("Found the last Git tag: #{from}")
            to = "HEAD"
          end
          UI.success("Collecting Git commits between #{from} and #{to}")
        end

        # Normally it is not good practice to take arbitrary input and convert it to a symbol
        # because prior to Ruby 2.2, symbols are never garbage collected. However, we've
        # already validated that the input matches one of our allowed values, so this is OK
        merge_commit_filtering = params[:merge_commit_filtering].to_sym

        # We want to be specific and exclude nil for this comparison
        if params[:include_merges] == false
          merge_commit_filtering = :exclude_merges
        end

        params[:path] = "./" unless params[:path]

        Dir.chdir(params[:path]) do
          changelog = if params[:commits_count]
            changelog_titles = Actions.git_log_last_commits(
              params[:pretty],
              params[:commits_count],
              merge_commit_filtering,
              params[:date_format],
              params[:ancestry_path],
            )
            changelog_commit_hashes = Actions.git_log_last_commits(
              "%h",
              params[:commits_count],
              merge_commit_filtering,
              params[:date_format],
              params[:ancestry_path],
            )
          else
            changelog_titles = Actions.git_log_between(
              params[:pretty],
              from,
              to,
              merge_commit_filtering,
              params[:date_format],
              params[:ancestry_path],
            )
            changelog_commit_hashes = Actions.git_log_between(
              "%h",
              from,
              to,
              merge_commit_filtering,
              params[:date_format],
              params[:ancestry_path],
            )
          end
          changelog = build_changelog(changelog_titles, changelog_commit_hashes, params.fetch(:file_key_patterns))

          changelog = changelog.gsub("\n\n", "\n") if changelog # as there are duplicate newlines

          # Process patterns before returning the string
          replace_patterns = params.fetch(:replace_patterns)
          replace_patterns.each do |key, value|
            changelog = changelog.gsub(key, value)
          end

          Actions.lane_context[SharedValues::FL_CHANGELOG] = changelog

          if params[:quiet] == false
            puts("")
            puts(changelog)
            puts("")
          end

          changelog
        end
      end

      def self.build_changelog(changelog_titles, changelog_commit_hashes, file_key_patterns)
        split_changelog_titles = changelog_titles.split("\n")
        split_changelog_commit_hashes = changelog_commit_hashes.split("\n")

        split_changelog_commit_hashes.each_with_index do |commit_hash, index|
          key_symbols_for_commit = []
          changes = Actions.sh("git diff --name-only #{commit_hash}^!", log: false).chomp.split("\n")

          file_key_patterns.each do |title_and_patterns, symbol|
            _title, patterns = title_and_patterns
            if changes.any? { |change| patterns.any? { |pattern| change.match(pattern) } }
              key_symbols_for_commit << symbol
            end
          end

          split_changelog_titles[index] =
            "#{split_changelog_titles[index]}#{" [#{key_symbols_for_commit.join}]" unless key_symbols_for_commit.empty?}"
        end

        key_text = "\n\n\nKey:\n" + file_key_patterns.map do |title_and_patterns, symbol|
          title, _patterns = title_and_patterns
          "#{symbol} #{title}"
        end.join(", ") unless file_key_patterns.empty?

        changelog_texts = split_changelog_titles.dup.append(key_text).compact

        changelog_texts.join("\n")
      end

      def self.get_latest_git_tag(check_all_repo)
        command = if check_all_repo
          "git describe --tags `git rev-list --tags --max-count=1`"
        else
          "git describe --abbrev=0 --tags"
        end

        sh(command).chomp
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Collect git commit messages into a changelog"
      end

      def self.details
        "By default, messages will be collected back to the last tag, but the range can be controlled"
      end

      def self.output
        [
          ["FL_CHANGELOG", "The changelog string generated from the collected git commit messages"],
        ]
      end

      # rubocop:disable Layout/LineLength
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :between,
            env_name: "FL_GIT_CHANGELOG_BETWEEN",
            description: "Array containing two Git revision values between which to collect messages, "\
              "you mustn't use it with :commits_count key at the same time",
            optional: true,
            type: Array, # allow Array, String both
            conflicting_options: [:commits_count],
            verify_block: proc do |value|
                            UI.user_error!(":between must not contain nil values") if value.any?(&:nil?)
                            UI.user_error!(":between must be an array of size 2") unless (value || []).size == 2
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :commits_count,
            env_name: "FL_GIT_CHANGELOG_COUNT",
            description: "Number of commits to include in changelog, you mustn't use it with :between key at the same time",
            optional: true,
            conflicting_options: [:between],
            type: Integer,
            verify_block: proc do |value|
                            UI.user_error!(":commits_count must be >= 1") if value.to_i < 1
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :path,
            env_name: "FL_GIT_CHANGELOG_PATH",
            description: "Path of the git repository",
            optional: true,
            default_value: "./",
          ),
          FastlaneCore::ConfigItem.new(
            key: :pretty,
            env_name: "FL_GIT_CHANGELOG_PRETTY",
            description: "The format applied to each commit while generating the collected value",
            optional: true,
            default_value: "%B",
          ),
          FastlaneCore::ConfigItem.new(
            key: :date_format,
            env_name: "FL_GIT_CHANGELOG_DATE_FORMAT",
            description: "The date format applied to each commit while generating the collected value",
            optional: true,
          ),
          FastlaneCore::ConfigItem.new(
            key: :ancestry_path,
            env_name: "FL_GIT_CHANGELOG_ANCESTRY_PATH",
            description: "Whether or not to use ancestry-path param",
            optional: true,
            default_value: false,
            type: Boolean,
          ),
          FastlaneCore::ConfigItem.new(
            key: :quiet,
            env_name: "FL_GIT_CHANGELOG_TAG_QUIET",
            description: "Whether or not to disable changelog output",
            optional: true,
            default_value: false,
            type: Boolean,
          ),
          FastlaneCore::ConfigItem.new(
            key: :include_merges,
            deprecated: "Use `:merge_commit_filtering` instead",
            env_name: "FL_GIT_CHANGELOG_INCLUDE_MERGES",
            description: "Whether or not to include any commits that are merges",
            optional: true,
            type: Boolean,
            verify_block: proc do |value|
                            UI.important("The :include_merges option is deprecated. Please use :merge_commit_filtering instead") unless value.nil?
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :merge_commit_filtering,
            env_name: "FL_GIT_CHANGELOG_MERGE_COMMIT_FILTERING",
            description: "Controls inclusion of merge commits when collecting the changelog. Valid values: #{GIT_MERGE_COMMIT_FILTERING_OPTIONS.map do |o|
                                                                                                               "`:#{o}`"
                                                                                                             end.join(", ")}",
            optional: true,
            default_value: "include_merges",
            verify_block: proc do |value|
                            matches_option = GIT_MERGE_COMMIT_FILTERING_OPTIONS.any? { |opt| opt.to_s == value }
                            UI.user_error!("Valid values for :merge_commit_filtering are #{GIT_MERGE_COMMIT_FILTERING_OPTIONS.map do |o|
                                                                                             "'#{o}'"
                                                                                           end.join(", ")}") unless matches_option
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :replace_patterns,
            env_name: "FL_GIT_CHANGELOG_REPLACE_PATTERNS",
            description: "Hash of patterns to replace and their substitutions",
            optional: true,
            type: Hash,
            default_value: {},
          ),
          FastlaneCore::ConfigItem.new(
            key: :file_key_patterns,
            env_name: "FL_GIT_CHANGELOG_FILE_KEY_PATTERNS",
            description: "Hash of title, file paths patterns and symbols to add a key to identify the changes in each commit",
            optional: true,
            type: Hash,
            default_value: {},
          ),
          FastlaneCore::ConfigItem.new(
            key: :check_all_repo,
            env_name: "FL_GIT_CHANGELOG_CHECK_ALL_REPO",
            description: "Check the whole repo history instead of the currently checked-out branch",
            optional: true,
            default_value: false,
            type: Boolean,
          ),
        ]
      end
      # rubocop:enable Layout/LineLength

      def self.return_value
        "Returns a String containing your formatted git commits"
      end

      def self.return_type
        :string
      end

      def self.author
        ["mfurtak", "asfalcone", "SiarheiFedartsou", "allewun", "adriangl"]
      end

      def self.is_supported?(platform)
        true
      end

      # rubocop:disable Layout/LineLength
      def self.example_code
        [
          "git_changelog",
          'git_changelog(
                between: ["7b092b3", "HEAD"],            # Optional, lets you specify a revision/tag range between which to collect commit info
                pretty: "- (%ae) %s",                    # Optional, lets you provide a custom format to apply to each commit when generating the changelog text
                date_format: "short",                    # Optional, lets you provide an additional date format to dates within the pretty-formatted string
                merge_commit_filtering: "exclude_merges"  # Optional, lets you filter out merge commits
                replace_patterns: {                      # Optional, lets you add replace patterns
                    /(\w+)/ => \'Hello \1\'
                },
                file_key_patterns: {                      # Optional, lets you add file key patterns to mark the commit titles with
                  ["Shared", ["app/shared"]] => "🔄",
                  ["App", ["app/src"]] => "🎲",
                }
              )',
        ]
      end
      # rubocop:enable Layout/LineLength

      def self.category
        :source_control
      end
    end
  end
end
