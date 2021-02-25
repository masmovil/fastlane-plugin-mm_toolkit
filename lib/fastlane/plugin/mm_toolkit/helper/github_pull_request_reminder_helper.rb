# frozen_string_literal: true
module Fastlane
  module Actions
    # Returns the GitHub login and Webex email mapping to be used with github_pull_request_reminder's user_logins_and_mentions param
    def self.get_github_user_login_mention_for_webex(user_github_login, user_webex_email)
      "#{user_github_login}:<@personEmail:#{user_webex_email}|#{user_github_login}>"
    end

    # Returns the GitHub login and Slack handle formatted to be used with github_pull_request_reminder's user_logins_and_mentions param
    def self.get_github_user_login_mention_for_slack(user_github_login, user_slack_handle)
      "#{user_github_login}:<@#{user_slack_handle}>"
    end
  end
end
