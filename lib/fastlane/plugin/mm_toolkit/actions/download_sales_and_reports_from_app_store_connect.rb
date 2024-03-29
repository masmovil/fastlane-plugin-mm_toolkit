# frozen_string_literal: true

require_relative "../helper/app_store_ax_connector/app_store_connect_account"
require_relative "../helper/app_store_ax_connector/app_store_connect_api"

module Fastlane
  module Actions
    class DownloadSalesAndReportsFromAppStoreConnectAction < Action
      def self.run(params)
        issuer_id = params.fetch(:issuer_id)
        key_id = params.fetch(:key_id)
        vendor_number = params.fetch(:vendor_number)
        private_key_content = params[:private_key_content]
        private_key_path = params[:private_key_path]

        fetch(issuer_id, key_id, private_key_path, private_key_content, vendor_number)
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.fetch(issuer_id, key_id, private_key_path, private_key_content, vendor_number)
        UI.important("Fetching sales and reports...")
        private_key = nil

        if private_key_path.nil? && private_key_content.nil?
          UI.user_error!("You must provide a private_key_path or private_key_content")
        end

        unless private_key_path.nil?
          private_key = File.read(private_key_path)
        end

        unless private_key_content.nil?
          private_key = private_key_content
        end

        begin
          app_store_connect_account = AppStoreConnectAccount.new(issuer_id, key_id, private_key, vendor_number)
          app_store_connect_api = AppStoreConnectAPI.new(app_store_connect_account)
          sales_and_reports = app_store_connect_api.get_sales_and_reports

          UI.success("Sales and reports fetched!")
          sales_and_reports
        rescue => e
          UI.crash!("Sales and reports could not be fetched: #{e}/n #{e.backtrace.join("/n")}")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Downloads sales and reports from App Store Connect"
      end

      def self.details
        "The action downloads sales and reports from Apple Store Connect. "\
          "You can obtain the sales and reports data by checking the action result."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :issuer_id,
            env_name: "FL_DOWNLOAD_SALES_AND_REPORTS_FROM_APP_STORE_CONNECT_ISSUER_ID",
            description: "issuer_id from Apple Store Connect",
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :key_id,
            env_name: "FL_DOWNLOAD_SALES_AND_REPORTS_FROM_APP_STORE_CONNECT_KEY_ID",
            description: "key_id from Apple Store Connect",
            type: String,
          ),
          FastlaneCore::ConfigItem.new(
            key: :private_key_path,
            env_name: "FL_DOWNLOAD_SALES_AND_REPORTS_FROM_APP_STORE_CONNECT_PRIVATE_KEY_PATH",
            description: "Path to the private key file from Apple Store Connect",
            type: String,
            conflicting_options: [:private_key_content],
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :private_key_content,
            env_name: "FL_DOWNLOAD_SALES_AND_REPORTS_FROM_APP_STORE_CONNECT_PRIVATE_KEY_CONTENT",
            description: "Content of the private key file from Apple Store Connect",
            type: String,
            conflicting_options: [:private_key_path],
            optional: true,
            default_value: nil,
          ),
          FastlaneCore::ConfigItem.new(
            key: :vendor_number,
            env_name: "FL_DOWNLOAD_SALES_AND_REPORTS_FROM_APP_STORE_CONNECT_VENDOR_NUMBER",
            description: "Vendor number from Apple Store Connect",
            type: Integer,
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
        :app_store_connect
      end
    end
  end
end
