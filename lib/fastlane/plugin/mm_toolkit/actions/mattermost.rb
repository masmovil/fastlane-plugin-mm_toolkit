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

        send_to_mattermost(hook_url, text, username, icon_url, channel, icon_emoji, attachments, props, type)
      end

      #####################################################
      # @!group support functions
      #####################################################

      # rubocop:disable Metrics/ParameterLists
      def self.send_to_mattermost(hook_url, text, username, icon_url, channel, icon_emoji, attachments, props, type)
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

        Net::HTTP.post(hook_url, body.to_json, header)
      rescue => exception
        UI.error("Exception: #{exception}")
      ensure
        UI.success("Successfully push messages to Mattermost")
      end

      def self.working_url?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Fastlane action to push messages to Mattermost"
      end

      def self.authors
        ["cpfriend1721994", "adriangl"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Fastlane action to push messages to Mattermost"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
            env_name: "MATTERMOST_WEBHOOKS_URL",
            sensitive: true,
            description: "Mattermost Incoming Webhooks URL",
            verify_block: proc do |value|
                            UI.user_error!("Invalid Mattermost hook URL") unless working_url?(value)
                          end),
          FastlaneCore::ConfigItem.new(key: :text,
            env_name: "MATTERMOST_WEBHOOKS_PARAMS",
            description: "Mattermost Incoming Webhooks Params"),
          FastlaneCore::ConfigItem.new(key: :username,
            env_name: "MATTERMOST_WEBHOOKS_USERNAME",
            optional: true,
            description: "Mattermost Incoming Webhooks Username",
            default_value: DEFAULT_USERNAME),
          FastlaneCore::ConfigItem.new(key: :icon_url,
            env_name: "MATTERMOST_WEBHOOKS_ICON_URL",
            optional: true,
            description: "Mattermost Incoming Webhooks Icon URL",
            default_value: DEFAULT_ICON_URL),
          FastlaneCore::ConfigItem.new(key: :channel,
            env_name: "MATTERMOST_WEBHOOKS_CHANNEL",
            optional: true,
            description: "Mattermost Incoming Webhooks Channel"),
          FastlaneCore::ConfigItem.new(key: :icon_emoji,
            env_name: "MATTERMOST_WEBHOOKS_ICON_EMOJI",
            optional: true,
            description: "Mattermost Incoming Webhooks Icon Emoji"),
          FastlaneCore::ConfigItem.new(key: :attachments,
            env_name: "MATTERMOST_WEBHOOKS_ATTACHMENTS",
            optional: true,
            description: "Mattermost Incoming Webhooks Attachments",
            type: Array),
          FastlaneCore::ConfigItem.new(key: :props,
            env_name: "MATTERMOST_WEBHOOKS_PROPS",
            optional: true,
            description: "Mattermost Incoming Webhooks Properties",
            type: Hash),
          FastlaneCore::ConfigItem.new(key: :type,
            env_name: "MATTERMOST_WEBHOOKS_TYPE",
            optional: true,
            description: "Mattermost Incoming Webhooks Type"),
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
    end
  end
end
