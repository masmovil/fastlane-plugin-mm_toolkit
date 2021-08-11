# frozen_string_literal: true
module Fastlane
  module Actions
    module SharedValues
      TAG_TRAIN_HEAD_ALREADY_TAGGED = :TAG_TRAIN_HEAD_ALREADY_TAGGED
      TAG_TRAIN_NEW_TAG_CREATED = :TAG_TRAIN_NEW_TAG_CREATED
      TAG_TRAIN_LATEST_VERSION = :TAG_TRAIN_LATEST_VERSION
      TAG_TRAIN_LATEST_TAG = :TAG_TRAIN_LATEST_TAG
      TAG_TRAIN_COMMIT_COUNT = :TAG_TRAIN_COMMIT_COUNT
      TAG_TRAIN_YEAR = :TAG_TRAIN_YEAR
      TAG_TRAIN_WEEK_OF_YEAR = :TAG_TRAIN_WEEK_OF_YEAR
    end

    class TagTrainAction < Action
      def self.run(params)
        create_new_commit = params.fetch(:create_new_commit)

        UI.message("Reading current tags…")
        latest_version = get_version_from_latest_git_tag_from_branch
        head_tag = get_head_tag_from_git
        week_data = get_week_data
        weekly_version = get_weekly_version

        head_already_tagged = false
        new_tag_created = false
        latest_tag = ""
        output_year = nil
        output_week_of_year = nil

        UI.header("Tag analysis")
        if !head_tag.empty? && !create_new_commit
          head_already_tagged = true
          latest_tag = head_tag

          UI.important("HEAD is already tagged as #{head_tag}, no new tag is needed")
        elsif Gem::Version.new(latest_version) < Gem::Version.new(weekly_version)
          new_tag_created = true
          latest_tag = "v#{weekly_version}"
          latest_version = weekly_version
          output_year = week_data[:year].to_i
          output_week_of_year = week_data[:week_of_year].to_i

          if create_new_commit
            UI.message("Creating new commit to set the weekly tag…")

            other_action.ensure_git_status_clean
            create_weekly_commit(output_week_of_year)
          end

          other_action.add_git_tag(
            tag: latest_tag,
            message: "Happy week #{output_week_of_year}!"
          )

          UI.success("New tag #{latest_tag} created!")
        else
          latest_tag = "v#{latest_version}"
          UI.important("No new tag is needed, we are on the correct train 🚂")
        end

        commit_count = get_commit_count_in_head_from_git

        UI.success("Using #{latest_tag} (#{commit_count})")

        Actions.lane_context[SharedValues::TAG_TRAIN_HEAD_ALREADY_TAGGED] = head_already_tagged
        Actions.lane_context[SharedValues::TAG_TRAIN_NEW_TAG_CREATED] = new_tag_created
        Actions.lane_context[SharedValues::TAG_TRAIN_LATEST_VERSION] = latest_version
        Actions.lane_context[SharedValues::TAG_TRAIN_LATEST_TAG] = latest_tag
        Actions.lane_context[SharedValues::TAG_TRAIN_COMMIT_COUNT] = commit_count
        Actions.lane_context[SharedValues::TAG_TRAIN_YEAR] = output_year
        Actions.lane_context[SharedValues::TAG_TRAIN_WEEK_OF_YEAR] = output_week_of_year

        {
          new_tag_created: new_tag_created,
          latest_version: latest_version,
          commit_count: commit_count,
          year: output_year,
          week_of_year: output_week_of_year,
        }
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.get_week_data
        date = Date.today
        # Using ISO-8601 week-based year and week number.
        two_digit_year = date.strftime("%g").to_i
        two_digit_week_of_year = date.strftime("%V").to_i

        { year: two_digit_year, week_of_year: two_digit_week_of_year }
      end

      def self.get_weekly_version
        week_data = get_week_data

        "#{week_data[:year]}.#{week_data[:week_of_year]}.0"
      end

      def self.get_version_from_latest_git_tag_from_branch
        Actions.get_latest_version_from_branch
      end

      def self.get_commit_count_in_head_from_git
        other_action.number_of_commits
      end

      def self.get_head_tag_from_git
        sh("git tag --contains HEAD").strip
      end

      def self.create_weekly_commit(week_number)
        sh("git commit -m \"Happy week #{week_number}!\" --allow-empty --no-verify")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate weekly-based tags in your git repository suitable for release trains"
      end

      def self.details
        "The action generates tags based on the week of the year. The syntax of the generated tags (and the tags the action expect "\
        "as input) is as follows: "\
        "\nv[two_digit_year].[two_digit_week].0"\
        "\nThe tag conforms to ISO-8601 standard to calculate weeks between a year: this means that the first week of the year will be "\
        "the one that contains the first Thursday"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :create_new_commit,
            env_name: "FL_TAG_TRAIN_CREATE_NEW_COMMIT",
            description: "If true, creates a new empty commit in the branch to set the new tag to",
            type: Boolean,
            optional: true,
            default_value: false),
        ]
      end

      def self.output
        [
          ["TAG_TRAIN_HEAD_ALREADY_TAGGED",
           "True or false indicating if the current HEAD was already tagged before running the action",],
          ["TAG_TRAIN_NEW_TAG_CREATED",
           "True or false indicating if a new tag has been created",],
          ["TAG_TRAIN_LATEST_VERSION",
           "App version inferred from current tag",],
          ["TAG_TRAIN_COMMIT_COUNT",
           "Commit count in the current branch",],
          ["TAG_TRAIN_YEAR",
           "Year used in the weekly tag",],
          ["TAG_TRAIN_WEEK_OF_YEAR",
           "Week of year used in the weekly tag",],
        ]
      end

      def self.return_type
        # Check https://github.com/fastlane/fastlane/blob/0d1aa50045d57975d8b9e5d5f1f489d82ee0f437/fastlane/lib/fastlane/action.rb#L23
        # for available types
        :hash
      end

      def self.return_value
        "The `new_tag_created`, `latest_version`, `commit_count`, `year` and `week_of_year` from which the weekly tag is generated."\
        "\nIf no new version is tagged, `year` and `week_of_year` will be nil."
      end

      def self.authors
        ["sebastianvarela", "adriangl"]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end

      def self.example_code
        [
          '
            version_hash = tag_train
            latest_version, commit_count = version_hash.values_at(:latest_version, :commit_count)
            puts "The latest version is #{latest_version}!"
            ',
        ]
      end

      def self.category
        # Check https://github.com/fastlane/fastlane/blob/0d1aa50045d57975d8b9e5d5f1f489d82ee0f437/fastlane/lib/fastlane/action.rb#L6
        # for available categories
        :source_control
      end
    end
  end
end
