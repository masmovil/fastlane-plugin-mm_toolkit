# frozen_string_literal: true

module Fastlane
  module Actions
    class GoogleChatAction < Action
      GOOGLE_CHAT_HOOK_URL_REGEX = %r{https://chat\.googleapis\.com/v1/spaces/\w+/messages\?key=[A-Za-z0-9-_%]+&token=[A-Za-z0-9-_%]+}

      def self.run(params)
        send_message(params)
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.send_message(params)
        uri = URI(params[:url])
        markdown = format_message(params)
        fail_on_error = params[:fail_on_error]

        begin
          # Launch the request
          res = Net::HTTP.post(uri, { "text" => markdown }.to_json, { "Content-Type" => "application/json", "charset" => "UTF-8" })

          # Check if the response went OK. If it did notify the user, else check the response for alternatives
          case res
          when Net::HTTPSuccess
            UI.success("Google Chat message has been sent successfully!")
          else
            message = "Error sending Google Chat message. Review that the hook URL is OK and try again later.\n"\
              "Error code: #{res.code}\n"\
              "Response body: #{res.body}"
            if fail_on_error
              UI.user_error!(message)
            else
              UI.error(message)
            end
          end
        rescue => exception
          UI.error("An exception happened while sending the Google Chat message:\n#{exception}")
        end
      end

      def self.format_message(params)
        markdown = ""

        success = params[:success]
        prefix = if success.nil?
          ""
        elsif success # We'd use blank?, but we don't have Rails
          "## ✅ "
        else
          "## 🛑 "
        end

        markdown += "#{prefix}#{params[:message]}"

        markdown += "\n\n\n" unless params[:payload].empty?

        markdown += params[:payload].map do |k, v|
          "**#{k}**  \n#{v.to_s.gsub("\n", "  \n")}  \n"
        end.join("")

        Actions::MrkdwnHelper.format_mrkdwn(markdown)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Send a message to your Google Chat space"
      end

      def self.details
        "The action allows users to send basic messages through an "\
          "[Incoming Webhook](https://developers.google.com/chat/how-tos/webhooks) "\
          "to the space that the webhook is configured to. "\
          "You can also add some payload data and metadata related to builds if you use the action to display CI/CD related messages."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
            env_name: "FL_GOOGLE_CHAT_URL",
            description: "Hook URL to a Webex resource to post messages",
            is_string: true,
            sensitive: true,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("Invalid Google Chat hook URL") unless value.match?(GOOGLE_CHAT_HOOK_URL_REGEX)
            end),
          FastlaneCore::ConfigItem.new(key: :message,
            env_name: "FL_GOOGLE_CHAT_MESSAGE",
            description:
              "The message that should be displayed on Webex. "\
              "The message should be formatted in Markdown language",
            is_string: true,
            optional: false),
          FastlaneCore::ConfigItem.new(key: :message_max_retries,
            env_name: "FL_GOOGLE_CHAT_MESSAGE_MAX_RETRIES",
            description:
              "How many retries we should do if the message sending fails",
            is_string: false,
            optional: true,
            default_value: 3),
          FastlaneCore::ConfigItem.new(key: :payload,
            env_name: "FL_GOOGLE_CHAT_PAYLOAD",
            description:
              "Add additional information to this message."\
              "The payload must be a hash containing any key with any value",
            is_string: false,
            optional: true,
            default_value: {}),
          FastlaneCore::ConfigItem.new(key: :success,
            env_name: "FL_GOOGLE_CHAT_SUCCESS",
            description:
              "Was this build successful? (true/false)."\
              "If not specified, no build-related format will be appended to the message",
            is_string: false,
            optional: true,
            default_value: nil),
          FastlaneCore::ConfigItem.new(key: :fail_on_error,
            env_name: "FL_GOOGLE_CHAT_FAIL_ON_ERROR",
            description:
              "Should an error sending the Webex post cause a failure? (true/false)",
            is_string: false,
            optional: true,
            default_value: false),
        ]
      end

      def self.authors
        ["adriangl"]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end

      def self.example_code
        [
          '
            # You can send a simple message
            google_chat(message: "This is a test message")

            # Or enrich it with payloads and success metadata
            google_chat(message: "This is a test message", success: true, payload: {"Build": "Success"})
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
