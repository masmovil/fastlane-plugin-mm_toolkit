# frozen_string_literal: true
require_relative '../helper/app_store_ax_connector/app_store_connect_account'
require_relative '../helper/app_store_ax_connector/app_store_connect_api'

module Fastlane
    module Actions
      class DownloadReviewsFromAppStoreConnectAction < Action
        def self.run(params)
      
          issuer_id = params.fetch(:issuer_id)
          key_id = params.fetch(:key_id)
          vendor_number = params.fetch(:vendor_number)
          app_id = params.fetch(:app_id)
          private_key_content = params[:private_key_content]
          private_key_path = params[:private_key_path]

          fetch(issuer_id, key_id, private_key_path, private_key_content, vendor_number, app_id)
        end
  
        #####################################################
        # @!group support functions
        #####################################################
  
        def self.fetch(issuer_id, key_id, private_key_path, private_key_content, vendor_number, app_id)
          UI.important("Fetch reviews...")
          private_key = nil

          if private_key_path.nil? && private_key_content.nil? 
            UI.user_error!("You must provide a private_key_path or private_key_content")
          end

          if !private_key_path.nil? 
            private_key = File.read(private_key_path)
          end

          if !private_key_content.nil? 
            private_key = private_key_content
          end

          begin  
            app_store_connect_account = AppStoreConnectAccount.new(issuer_id, key_id, private_key, vendor_number)
            app_store_connect_api = AppStoreConnectAPI.new(app_store_connect_account)
            reviews = app_store_connect_api.get_reviews(app_id)

            UI.success("Reviews downloaded!")
            reviews
          rescue
            UI.crash!("Reviews could not be downloaded")
          end
        end
  
        #####################################################
        # @!group Documentation
        #####################################################
  
        def self.description
          "Downloads reviews from App Store Connect"
        end
  
        def self.details
          "The action downloads reviews from from Apple Store Connect"\
          "You can obtain the reviews of an scanning the result of `app_store_connect_api.get_reviews(app_id)`"
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(
              key: :issuer_id,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_ISSUER_ID",
              description: "issuer_id from Apple Store Connect",
              type: String,
            ),
            FastlaneCore::ConfigItem.new(
              key: :key_id,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_KEY_ID",
              description: "key_id from Apple Store Connect",
              type: String,
            ),
            FastlaneCore::ConfigItem.new(
              key: :private_key_path,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_PRIVATE_KEY_PATH",
              description: "Path to the private key file from Apple Store Connect",
              type: String,
              conflicting_options: [:private_key_content],
              optional: true,
              default_value: nil,
            ),
            FastlaneCore::ConfigItem.new(
              key: :private_key_content,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_PRIVATE_KEY_CONTENT",
              description: "Content of the private key file from Apple Store Connect",              
              type: String,
              conflicting_options: [:private_key_path],
              optional: true,
              default_value: nil,
            ),
            FastlaneCore::ConfigItem.new(
              key: :vendor_number,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_VENDOR_NAME",
              description: "Vendor name from Apple Store Connect",
              type: String
            ),
            FastlaneCore::ConfigItem.new(
              key: :app_id,
              env_name: "FL_DOWNLOAD_REVIEWS_FROM_APP_STORE_CONNECT_APP_ID",
              description: "App id from Apple Store Connect",
              type: String
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
  