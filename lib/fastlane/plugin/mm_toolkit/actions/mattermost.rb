# frozen_string_literal: true

module Fastlane
  module Actions
    class MattermostAction < Action
      DEFAULT_USERNAME = "Fastlane Mattermost"
      DEFAULT_ICON_URL = "https://fastlane.tools/assets/img/fastlane_icon.png"

      def self.run(params)
        hook_url = URI(params.fetch(:url))
        text = params.fetch(:text)
        username = params.fetch(:username)
        icon_url = params.fetch(:icon_url)

        channel = params[:channel]
        icon_emoji = params[:icon_emoji]
        attachments = params[:attachments]
        props = params[:props]
        type = params[:type]

        send_message(hook_url, text, username, icon_url, channel, icon_emoji, attachments, props, type)
      end

      #####################################################
      # @!group support functions
      #####################################################

      # rubocop:disable Metrics/ParameterLists
      def self.send_message(hook_url, text, username, icon_url, channel, icon_emoji, attachments, props, type)
        UI.user_error!("You must set a 'text' or non-empty 'attachments' in order to send a message") unless has_required_fields?(
          text,
          attachments,
        )
        begin
          header = {
            "Content-Type": "application/json",
          }
          body = {
            "text": text,
            "username": username,
            "icon_url": icon_url,
          }

          body.merge!("channel": channel) unless channel.nil?
          body.merge!("icon_emoji": icon_emoji) unless icon_emoji.nil?
          body.merge!("attachments": attachments) unless attachments.nil?
          body.merge!("props": props) unless props.nil?
          body.merge!("type": type) unless type.nil?

          res = Net::HTTP.post(hook_url, body.to_json, header)

          case res
          when Net::HTTPSuccess
            UI.success("Successfully sent message to Mattermost")
          else
            message = "Error sending message to Mattermost. Review that the hook URL is OK and try again later.\n"\
              "Error code: #{res.code}\n"\
              "Response body: #{res.body}"

            UI.error(message)
          end
        rescue => exception
          UI.error("Exception sending message to Mattermost: #{exception}")
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def self.working_url?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end

      def self.has_required_fields?(text, attachments)
        if text.nil?
          if attachments.nil? || attachments.empty?
            return false
          end
        end

        true
      end

      def self.is_custom_type?(type)
        if type.nil?
          true # If null value, let it pass
        else
          type.start_with?("custom_")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Fastlane action to push messages to Mattermost"
      end

      def self.authors
        ["adriangl", "cpfriend1721994"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Create an incoming webhook [(docs)](https://developers.mattermost.com/integrate/webhooks/incoming/#create-an-incoming-webhook) "\
          "and use it to send messages to your Mattermost instance"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :url,
            env_name: "MATTERMOST_WEBHOOK_URL",
            sensitive: true,
            description: "Mattermost Incoming Webhooks URL",
            verify_block: proc do |value|
                            UI.user_error!("Invalid Mattermost webhook URL") unless working_url?(value)
                          end,
          ),
          FastlaneCore::ConfigItem.new(
            key: :text,
            env_name: "MATTERMOST_TEXT",
            optional: true,
            description: "Markdown-formatted message to display in the post",
          ),
          FastlaneCore::ConfigItem.new(
            key: :username,
            env_name: "MATTERMOST_USERNAME",
            optional: true,
            description: "Overrides the username the message posts as",
            default_value: DEFAULT_USERNAME,
          ),
          FastlaneCore::ConfigItem.new(
            key: :icon_url,
            env_name: "MATTERMOST_ICON_URL",
            optional: true,
            description: "Overrides the profile picture the message posts with",
            default_value: DEFAULT_ICON_URL,
          ),
          FastlaneCore::ConfigItem.new(
            key: :channel,
            env_name: "MATTERMOST_CHANNEL",
            optional: true,
            description: "Overrides the channel the message posts in. Use the channel's name and not the display name, "\
              "e.g. use `town-square`, not `Town Square`",
          ),
          FastlaneCore::ConfigItem.new(
            key: :icon_emoji,
            env_name: "MATTERMOST_ICON_EMOJI",
            optional: true,
            description: "Overrides the profile picture and `icon_url` parameter",
          ),
          FastlaneCore::ConfigItem.new(
            key: :attachments,
            env_name: "MATTERMOST_ATTACHMENTS",
            optional: true,
            description: "Message attachments used for richer formatting options. "\
              "Check [https://docs.mattermost.com/developer/message-attachments.html](the documentation) for more details",
            type: Array,
          ),
          FastlaneCore::ConfigItem.new(
            key: :props,
            env_name: "MATTERMOST_PROPS",
            optional: true,
            description: "Sets the post `props`, a JSON property bag for storing extra or meta data on the post",
            type: Hash,
          ),
          FastlaneCore::ConfigItem.new(
            key: :type,
            env_name: "MATTERMOST_TYPE",
            optional: true,
            description: "Sets the post `type`, mainly for use by plugins. If not blank, must begin with `custom_`",
            verify_block: proc do |value|
                            UI.user_error!("The type must start with 'custom_'") unless is_custom_type?(value)
                          end,
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'mattermost(
            url: "https://example.mattermost.com/hooks/xxx-generatedkey-xxx",
            text: "Hello, this is some text\nThis is more text. :tada:",
            username: "Fastlane Mattermost",
            icon_url: "https://www.mattermost.org/wp-content/uploads/2016/04/icon.png"
          )',
          'mattermost(
            url: "https://example.mattermost.com/hooks/xxx-generatedkey-xxx",
            text: "Hello, this is some text\nThis is more text. :tada:",
            username: "Fastlane Mattermost",
            icon_url: "https://www.mattermost.org/wp-content/uploads/2016/04/icon.png",
            channel: ... ,
            icon_emoji: ... ,
            attachments: ... ,
            props: ... ,
            type: ...
          )',
        ]
      end

      def self.category
        :notifications
      end
    end
  end
end
