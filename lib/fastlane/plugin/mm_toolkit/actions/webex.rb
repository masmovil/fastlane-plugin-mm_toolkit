# frozen_string_literal: true
module Fastlane
  module Actions
    class WebexAction < Action
      WEBEX_HOOK_URL_REGEX = %r{https://(api\.ciscospark\.com|webexapis\.com)/v1/webhooks/incoming/\w+}

      def self.run(params)
        send_message(params)
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.send_message(params, retries = 0)
        # Stop retrying if we have reached max retries
        if retries > params[:message_max_retries]
          UI.user_error!("Max retries reached, the message could not be sent")
          return
        end

        uri = URI(params[:url])
        markdown = format_message(params)
        fail_on_error = params[:fail_on_error]

        begin
          # Launch the request
          res = Net::HTTP.post(uri, { "markdown" => markdown }.to_json, "Content-Type" => "application/json")

          # Check if the response went OK. If it did notify the user, else check the response for alternatives
          case res
          when Net::HTTPSuccess
            UI.success("Webex message has been sent successfully!")
          else
            # Check if there's a `Retry-After` header to retry the request.
            # If there is, retry the request after the specified time. Else, return an error
            # Docs: https://developer.webex.com/docs/api/basics#rate-limiting
            retry_after_value = res["Retry-After"]
            if retry_after_value.nil?
              message = "Error sending Webex message. Review that the hook URL is OK and try again later.\n"\
              "Error code: #{res.code}\n"\
              "Response body: #{res.body}"
              if fail_on_error
                UI.user_error!(message)
              else
                UI.error(message)
              end
            else
              retry_after_seconds = retry_after_value.to_i

              UI.important("Retrying Webex message sending after #{retry_after_seconds} seconds…")

              sleep(retry_after_seconds)

              send_message(params, retries + 1)
            end
          end
        rescue => exception
          UI.error("An exception happened while sending the Webex message:\n#{exception}")
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

        markdown += "\n\n" unless params[:payload].empty?

        markdown += params[:payload].map do |k, v|
          ">**#{k}**  \n>#{v.to_s.gsub("\n", "  \n>")}  \n"
        end.join("")

        markdown
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Send a message to your Webex space"
      end

      def self.details
        "The action allows users to send messages through an "\
        "[Incoming Webhook](https://apphub.webex.com/messaging/applications/incoming-webhooks-cisco-systems-38054) "\
        "to the space that the webhook is configured to. "\
        "You can also add some payload data and metadata related to builds if you use the action to display CI/CD related messages."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
            env_name: "FL_WEBEX_URL",
            description: "Hook URL to a Webex resource to post messages",
            is_string: true,
            sensitive: true,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("Invalid Webex hook URL") unless value.match?(WEBEX_HOOK_URL_REGEX)
            end),
          FastlaneCore::ConfigItem.new(key: :message,
            env_name: "FL_WEBEX_MESSAGE",
            description:
              "The message that should be displayed on Webex. "\
              "The message should be formatted in Markdown language",
            is_string: true,
            optional: false),
          FastlaneCore::ConfigItem.new(key: :message_max_retries,
            env_name: "FL_WEBEX_MESSAGE_MAX_RETRIES",
            description:
              "How many retries we should do if the message sending fails",
            is_string: false,
            optional: true,
            default_value: 3),
          FastlaneCore::ConfigItem.new(key: :payload,
            env_name: "FL_WEBEX_PAYLOAD",
            description:
              "Add additional information to this message."\
              "The payload must be a hash containing any key with any value",
            is_string: false,
            optional: true,
            default_value: {}),
          FastlaneCore::ConfigItem.new(key: :success,
            env_name: "FL_WEBEX_SUCCESS",
            description:
              "Was this build successful? (true/false)."\
              "If not specified, no build-related format will be appended to the message",
            is_string: false,
            optional: true,
            default_value: nil),
          FastlaneCore::ConfigItem.new(key: :fail_on_error,
            env_name: "WEBEX_FAIL_ON_ERROR",
            description:
              "Should an error sending the Webex post cause a failure? (true/false)",
            is_string: false,
            optional: true,
            default_value: false),
        ]
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
            # You can send a simple message
            webex(message: "This is a test message")

            # Or enrich it with payloads and success metadata
            webex(message: "This is a test message", success: true, payload: {"Build": "Success"})
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
