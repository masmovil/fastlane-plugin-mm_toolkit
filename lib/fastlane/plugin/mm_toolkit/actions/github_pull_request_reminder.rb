# frozen_string_literal: true
module Fastlane
  module Actions
    module SharedValues
      GITHUB_PULL_REQUEST_REMINDER_MESSAGE = :GITHUB_PULL_REQUEST_REMINDER_MESSAGE
      GITHUB_PULL_REQUEST_AWAITING_REVIEW_NUMBER = :GITHUB_PULL_REQUEST_AWAITING_REVIEW_NUMBER
    end

    class GithubPullRequestReminderAction < Action
      REQUESTED_REVIEWERS_KEY = "requested_reviewers"
      REQUESTED_TEAMS_KEY = "requested_teams"

      GITHUB_USERS_AND_MENTIONS_SEPARATOR = ","
      GITHUB_USERS_AND_MENTIONS_REGEX = /^(.+?):(.+?)$/

      def self.run(params)
        UI.message("Analyzing PRs in #{params[:repo]}…")

        pr_data = get_prs_with_pending_reviews(params)
        prs_awaiting_review_number = pr_data.size
        UI.important("There are #{prs_awaiting_review_number} PRs awaiting review!")

        markdown = if prs_awaiting_review_number > 0
          UI.message("Checking which users have to review PRs…")
          prs_and_pending_reviewers = map_prs_with_pending_reviewers(pr_data)

          UI.message("Sorting user logins and mentions…")
          user_logins_and_mentions_map =
            Helper::GithubUsersAndMentionsHelper.parse_github_users_and_mentions(params[:github_users_and_mentions])

          UI.message("Generating Markdown message…")
          generate_markdown(prs_and_pending_reviewers, user_logins_and_mentions_map)
        else
          "No PRs require reviews. Good job!"
        end

        Actions.lane_context[SharedValues::GITHUB_PULL_REQUEST_REMINDER_MESSAGE] = markdown
        Actions.lane_context[SharedValues::GITHUB_PULL_REQUEST_AWAITING_REVIEW_NUMBER] = prs_awaiting_review_number

        markdown
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.get_prs_with_pending_reviews(params)
        # Use the action github_api to query for PRs for the repo, and then filter the PRs by pending reviewers
        pr_data = other_action.github_api(
          server_url: params[:api_url],
          api_token: params[:api_token],
          http_method: "GET",
          path: "/repos/#{params[:repo]}/pulls",
          body: {}
        )[:json]
        require "pp"

        pp(pr_data)

        pr_data.filter { |pr| !pr[REQUESTED_REVIEWERS_KEY].empty? || !pr[REQUESTED_TEAMS_KEY].empty? }
      end

      def self.map_prs_with_pending_reviewers(prs)
        prs.flat_map do |pr|
          requested_reviewers_data = pr[REQUESTED_REVIEWERS_KEY].map do |requested_reviewer|
            { url: pr["html_url"], title: pr["title"], login: requested_reviewer["login"] }
          end

          requested_teams_data = pr[REQUESTED_TEAMS_KEY].map do |requested_team|
            { url: pr["html_url"], title: pr["title"], login: requested_team["slug"] }
          end

          requested_reviewers_data + requested_teams_data
        end
      end

      def self.generate_markdown(prs_and_pending_reviewers, user_logins_and_mentions_map)
        prs_and_pending_reviewers.map do |pr_and_pending_reviewers|
          github_user = pr_and_pending_reviewers[:login]
          user_mention = (user_logins_and_mentions_map && user_logins_and_mentions_map[github_user]) || github_user

          "Hey #{user_mention}! The PR [#{pr_and_pending_reviewers[:title]}](#{pr_and_pending_reviewers[:url]}) awaits your review!"
        end.join("\n")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate a message with GitHub pull request reminders"
      end

      def self.details
        "The action generates a Markdown message indicating the PRs that need review, optionally mentioning the people that "\
        "need to review said PR using a mapper of GitHub users to your messaging mention style of choice."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_url,
            env_name: "FL_GITHUB_API_URL",
            description:
             "The GitHub API URL - example: 'https://api.github.com'. Defaults to `$GITHUB_API_URL`",
            is_string: true,
            optional: true,
            default_value: ENV["GITHUB_API_URL"]),
          FastlaneCore::ConfigItem.new(key: :api_token,
            env_name: "FL_GITHUB_API_TOKEN",
            description:
             "API Token for GitHub with `repo` scope - generate one at https://github.com/settings/tokens. "\
             "Defaults to `$GITHUB_API_TOKEN`",
            sensitive: true,
            code_gen_sensitive: true,
            is_string: true,
            optional: true,
            default_value: ENV["GITHUB_API_TOKEN"]),
          FastlaneCore::ConfigItem.new(key: :repo,
            env_name: "FL_GITHUB_REPOSITORY",
            description:
             "Owner and repository name of the GitHub repo to check - example: octocat/Hello-World. "\
             "Defaults to `$GITHUB_REPOSITORY`",
            default_value: ENV["GITHUB_REPOSITORY"],
            optional: true),
          FastlaneCore::ConfigItem.new(key: :github_users_and_mentions,
            env_name: "FL_GITHUB_USER_MENTIONS",
            description:
             "Mapping of GitHub users to your own messaging system's mention style, "\
             "in a comma separated list of github_user:user_mention elements - "\
             "example: user1:mention1,user2:mention2",
            optional: true,
            is_string: true,
            default_value: ""),
        ]
      end

      def self.output
        [
          ["GITHUB_PULL_REQUEST_REMINDER_MESSAGE",
           "The pull request reminder message",],
          ["GITHUB_PULL_REQUEST_AWAITING_REVIEW_NUMBER",
           "The number of pull requests awaiting review",],
        ]
      end

      def self.return_type
        # Check https://github.com/fastlane/fastlane/blob/0d1aa50045d57975d8b9e5d5f1f489d82ee0f437/fastlane/lib/fastlane/action.rb#L23
        # for available types
        :string
      end

      def self.return_value
        "The pull request reminder message in Markdown format"
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
            reminder_message = github_pull_request_reminder(
              github_users_and_mentions: "github_user_1:your_messaging_system_mention,github_user_2:your_messaging_system_mention"
            )
            puts "The reminder message is: #{reminder_message}"
            ',
          '
            # You have helper functions for formatting mentions for Slack and Webex
            slack_reminder_message = github_pull_request_reminder(
              github_users_and_mentions: Actions.get_github_user_login_mention_for_slack("my_github_user", "my_slack_handle")
            )
            slack(message: slack_reminder_message)

            webex_reminder_message = github_pull_request_reminder(
              github_users_and_mentions: Actions.get_github_user_login_mention_for_webex("my_github_user", "my_webex_user@email.com")
            )
            webex(message: webex_reminder_message)
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
