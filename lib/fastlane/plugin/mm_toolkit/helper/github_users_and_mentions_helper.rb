# frozen_string_literal: true
module Fastlane
  module Helper
    class GithubUsersAndMentionsHelper
      GITHUB_USERS_AND_MENTIONS_SEPARATOR = ","
      GITHUB_USERS_AND_MENTIONS_REGEX = /^(.+?):(.+?)$/

      def self.parse_github_users_and_mentions(github_users_and_mentions)
        github_users_and_mentions&.split(GITHUB_USERS_AND_MENTIONS_SEPARATOR)&.flat_map do |github_user_and_mention|
          github_user_and_mention.scan(GITHUB_USERS_AND_MENTIONS_REGEX).map do |m|
            github_user = m[0]
            user_mention = m[1]
            { github_user => user_mention }
          end
        end&.reduce({}, :merge)
      end
    end
  end
end
