require 'fastlane/action'
require_relative '../helper/mm_toolkit_helper'

module Fastlane
  module Actions
    class MmToolkitAction < Action
      def self.run(params)
        UI.message("The mm_toolkit plugin is working!")
      end

      def self.description
        "MM ToolKit"
      end

      def self.authors
        ["Sebastián Varela"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "MM Toolkit for the people!"
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "MM_TOOLKIT_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
