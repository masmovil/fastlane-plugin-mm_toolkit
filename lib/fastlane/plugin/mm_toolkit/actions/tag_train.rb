# frozen_string_literal: true
module Fastlane
  module Actions
    module SharedValues
      TAG_TRAIN_HEAD_TAGGED = :TAG_TRAIN_HEAD_TAGGED
      TAG_TRAIN_NEW_TAG_CREATED = :TAG_TRAIN_NEW_TAG_CREATED
      TAG_TRAIN_VERSION_NUMBER = :TAG_TRAIN_VERSION_NUMBER
      TAG_TRAIN_BUILD_NUMBER = :TAG_TRAIN_BUILD_NUMBER
    end

    class TagTrainAction < Action
      def self.run(params)
        UI.message("Reading current tags...")
        version_number = get_tag_from_git
        build_number = get_commit_count_from_git
        head_tag = get_head_tag_from_git
        version_week = get_version_by_week_of_year
        head_tagged = false
        new_tag = false

        UI.header("Tag analysis")
        if head_tag != ""
          head_tagged = true
          UI.important("Head is tagged as #{head_tag}, this mean that no new commit are pushed")
        elsif Gem::Version.new(version_number) < Gem::Version.new(version_week)
          if params[:skip_new_tag_creation]
            UI.important("Be careful, a new tag should have been created, but the configuration forbids it.")
          else
            new_tag = true
            UI.success("Creating v#{version_week}...")
            sh("git tag v#{version_week} HEAD")
            version_number = version_week
            UI.message("done!")
          end
        else
          UI.important("No new tag is needed, we are on the correct train 🚂")
        end

        UI.success("Using v#{version_number} (#{build_number})")

        Actions.lane_context[SharedValues::TAG_TRAIN_HEAD_TAGGED] = head_tagged
        Actions.lane_context[SharedValues::TAG_TRAIN_NEW_TAG_CREATED] = new_tag
        Actions.lane_context[SharedValues::TAG_TRAIN_VERSION_NUMBER] = version_number
        Actions.lane_context[SharedValues::TAG_TRAIN_BUILD_NUMBER] = build_number
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.get_version_by_week_of_year
        date = Date.today
        # Using ISO-8601 week-based year and week number.
        week_of_year = date.strftime("%V").to_i
        year_two_dig = date.strftime("%g").to_i

        "#{year_two_dig}.#{week_of_year}"
      end

      def self.get_tag_from_git
        version_number = sh("git describe --tags --abbrev=0")
        version_number.gsub!(/[v\r\n]/, "")

        version_number
      end

      def self.get_commit_count_from_git
        build_number = sh("git rev-list --count HEAD")
        build_number.gsub!(/[\r\n]/, "")

        build_number
      end

      def self.get_head_tag_from_git
        head_tag = sh("git tag --contains HEAD")
        head_tag.gsub!(/[\r\n]/, "")

        head_tag
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Read and control tag for current version system"
      end

      def self.details
        "Read and control tag for current version system"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_new_tag_creation,
                                         env_name: "TAG_TRAIN_SKIP_NEW_TAG_CREATION",
                                         description: "Skip the creation of new tag if the current is not valid",
                                         is_string: false,
                                         default_value: false),
        ]
      end

      def self.output
        [
          ["TAG_TRAIN_HEAD_TAGGED", "True or false indicating if the current HEAD are tagged or not"],
          ["TAG_TRAIN_NEW_TAG_CREATED", "True or false indicating if a new tag has been created"],
          ["TAG_TRAIN_VERSION_NUMBER", "App version infered from current tag"],
          ["TAG_TRAIN_BUILD_NUMBER", "Build version"],
        ]
      end

      def self.authors
        ["sebastianvarela"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
