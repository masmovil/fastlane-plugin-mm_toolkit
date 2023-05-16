# frozen_string_literal: true

require_relative "../helper/app_store_ax_connector/big_query_controller"

module Fastlane
  module Actions
    class InsertDataInBigQueryAction < Action
      def self.run(params)
        credentials = params.fetch(:credentials)
        project_id = params.fetch(:project_id)
        dataset_id = params.fetch(:dataset_id)
        table_id = params.fetch(:table_id)
        rows = params.fetch(:rows)

        setup(credentials, project_id, dataset_id, table_id, rows)
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.setup(credentials, project_id, dataset_id, table_id, rows)
        UI.important("Setup Big Query...")
        big_query_controller = BigQueryController.new(credentials, project_id, dataset_id, table_id)
        UI.important("Insert rows in Big Query...")
        big_query_controller.insert(rows)
        UI.success("Succesfully insert rows in Big Query...!")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Insert rows in Big Query"
      end

      def self.details
        "The action inserts rows in big query"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :credentials,
            env_name: "FL_INSERT_ROWS_IN_BIG_QUERY_CREDENTIALS",
            description: "String or Hash with route or content at credentials file if you need more info go to https://www.rubydoc.info/gems/google-cloud-bigquery/Google/Cloud/Bigquery#new-class_method",
            optional: true,
            default_value: ENV["GOOGLE_APPLICATION_CREDENTIALS"],
          ),
          FastlaneCore::ConfigItem.new(
            key: :project_id,
            env_name: "FL_INSERT_ROWS_IN_BIG_QUERY_PROJECT_ID",
            description: "Big query project id",
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :dataset_id,
            env_name: "FL_INSERT_ROWS_IN_BIG_QUERY_DATASET_ID",
            description: "Big query dataset id",
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :table_id,
            env_name: "FL_INSERT_ROWS_IN_BIG_QUERY_TABLE_ID",
            description: "Big query table id",
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :rows,
            env_name: "FL_INSERT_ROWS_IN_BIG_QUERY_TABLE_ID",
            description: "Rows to insert in Big query",
            type: Hash,
          ),
        ]
      end

      def self.authors
        ["r-pedraza"]
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
