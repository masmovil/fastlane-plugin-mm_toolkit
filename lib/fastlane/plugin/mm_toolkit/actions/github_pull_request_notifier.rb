# frozen_string_literal: true
require "json"

module Fastlane
  module Actions
    module SharedValues
      GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_NAME = :GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_NAME
      GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_ACTION = :GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_ACTION
    end

    class GithubPullRequestNotifierAction < Action
      HANDLED_GITHUB_EVENTS = ["pull_request", "pull_request_review"]
      HANDLED_GITHUB_PULL_REQUEST_ACTIONS = ["opened", "closed"]

      def self.run(params)
        github_context = JSON.parse(params[:context])
        github_event_name = github_context["event_name"]

        unless HANDLED_GITHUB_EVENTS.include?(github_event_name)
          UI.user_error!("The GitHub context does not match a pull request event.")
          return
        end

        Actions.lane_context[SharedValues::GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_NAME] = github_event_name

        case github_event_name
        when "pull_request"
          handle_pull_request_event(params, github_context)
        when "pull_request_review"
          handle_pull_request_review_event(params, github_context)
        end
      end

      #####################################################
      # @!group support functions
      #####################################################

      def self.handle_pull_request_event(params, github_context)
        UI.message("Handling 'pull_request' event...")
        pr_event = github_context["event"]

        pr_action = pr_event["action"]
        Actions.lane_context[SharedValues::GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_ACTION] = pr_action

        unless HANDLED_GITHUB_PULL_REQUEST_ACTIONS.include?(pr_action)
          UI.user_error!("PR event \"#{pr_action}\" can not be handled")
        end

        case pr_action
        when "opened"
          handle_pr_opened(params, pr_event)
        when "closed"
          handle_pr_closed(params, pr_event)
        end
      end

      def self.handle_pull_request_review_event(params, github_context)
        UI.message("Handling 'pull_request_review' event...")
        pr_review_event = github_context["event"]

        pr_review_action = pr_review_event["action"]
        Actions.lane_context[SharedValues::GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_ACTION] = pr_review_action

        { message: get_pr_review_message(params, pr_review_event), payload: {} }
      end

      def self.handle_pr_opened(params, pr_event)
        UI.message("Handling 'pull_request' 'opened' event...")
        { message: get_pr_opened_message(params, pr_event), payload: get_pr_opened_payload(params, pr_event) }
      end

      def self.handle_pr_closed(params, pr_event)
        UI.message("Handling 'pull_request' 'closed' event...")
        { message: get_pr_closed_message(params, pr_event), payload: {} }
      end

      def self.get_pr_opened_message(_params, pr_event)
        UI.message("Handling PR 'pull_request' 'opened' event message...")
        repository = pr_event["repository"]
        repository_name = repository["name"]

        pr = pr_event["pull_request"]
        pr_number = pr["number"]
        pr_title = pr["title"]
        pr_body = pr["body"]

        pr_owner = pr["user"]
        pr_owner_name = pr_owner["login"]
        pr_relative_url = pr["_links"]["html"]["href"]
        pr_url = Helper::GithubUtilsHelper.compose_github_url(pr_relative_url)

        "[#{repository_name}] Pull request opened by #{pr_owner_name}\n"\
        "[\##{pr_number} #{pr_title}](#{pr_url})\n\n"\
        "#{pr_body}"
      end

      def self.get_pr_opened_payload(params, pr_event)
        UI.message("Handling PR 'pull_request' 'opened' event payload...")
        pr = pr_event["pull_request"]

        pr_source_branch = pr["head"]["ref"]
        pr_target_branch = pr["base"]["ref"]
        pr_changed_files = pr["changed_files"]
        pr_requested_reviewers = get_requested_reviewers_mentions(params, pr_event)
        pr_assignees = pr["assignees"].map { |assignee| assignee["login"] }
        pr_labels = pr["labels"].map { |label| label["name"] }

        {
          "Source branch" => pr_source_branch,
          "Target branch" => pr_target_branch,
          "Changed files" => pr_changed_files,
          "Reviewers" => pr_requested_reviewers.join(", "),
          "Assignees" => pr_assignees.join(", "),
          "Labels" => pr_labels.join(", "),
        }.filter { |_k, v| !v.to_s.empty? }
      end

      def self.get_pr_closed_message(_params, pr_event)
        UI.message("Handling PR 'pull_request' 'closed' event message...")
        repository = pr_event["repository"]
        repository_name = repository["name"]

        pr = pr_event["pull_request"]
        pr_number = pr["number"]
        pr_title = pr["title"]
        pr_relative_url = pr["_links"]["html"]["href"]
        pr_url = Helper::GithubUtilsHelper.compose_github_url(pr_relative_url)

        pr_owner = pr["user"]
        pr_owner_name = pr_owner["login"]

        pr_merged = pr["merged"]

        pr_closed_verb = pr_merged ? "merged" : "closed"

        "[#{repository_name}] Pull request [\##{pr_number} #{pr_title}](#{pr_url}) " + pr_closed_verb + " by #{pr_owner_name}\n"
      end

      def self.get_pr_review_message(params, pr_event)
        UI.message("Handling PR 'pull_request_review' event message...")

        pr_review_data = pr_event["review"]

        pr_review_state = pr_review_data["state"]
        pr_review_body = pr_review_data["body"]
        pr_review_relative_url = pr_review_data["_links"]["html"]["href"]
        pr_review_user = pr_review_data["user"]
        pr_review_user_name = pr_review_user["login"]

        pr = pr_event["pull_request"]
        pr_number = pr["number"]
        pr_title = pr["title"]

        pr_owner = pr["user"]
        pr_owner_name = pr_owner["login"]
        pr_relative_url = pr["_links"]["html"]["href"]

        pr_link = Helper::GithubUtilsHelper.compose_github_url(pr_review_relative_url.empty? ? pr_relative_url : pr_review_relative_url)

        # Possible states here: https://docs.github.com/en/graphql/reference/enums#pullrequestreviewstate
        msg = ""
        pr_owner_mention = get_user_mention(params, pr_owner_name)
        pr_reviewer_mention = get_user_mention(params, pr_review_user_name)

        case pr_review_state.downcase
        when "approved"
          msg = "#{pr_review_user_name} approved pull request "\
                "[\##{pr_number} #{pr_title}](#{pr_link}) opened by #{pr_owner_mention}"
        when "changes_requested"
          msg = "#{pr_review_user_name} requested changes on pull request"\
                "[\##{pr_number} #{pr_title}](#{pr_link}) opened by #{pr_owner_mention}"
        when "commented"
          msg = "#{pr_review_user_name} commented on pull request "\
                "[\##{pr_number} #{pr_title}](#{pr_link}) opened by #{pr_owner_mention}"
        when "dismissed"
          msg = "#{pr_owner_name} dismissed pull request review by #{pr_reviewer_mention} on pull request "\
                "[\##{pr_number} #{pr_title}](#{pr_link}) opened by #{pr_owner_mention}"
        when "pending"
          msg = "#{pr_reviewer_mention} has a pending pull request review on pull request "\
                "[\##{pr_number} #{pr_title}](#{pr_link}) opened by #{pr_owner_mention}"
        end

        unless !pr_review_body || pr_review_body.empty?
          msg += "\n> #{pr_review_body}"
        end

        msg
      end

      def self.get_requested_reviewers_mentions(params, pr_event)
        pr = pr_event["pull_request"]

        github_users =
          pr["requested_reviewers"].map { |reviewer| reviewer["login"] } + pr["requested_teams"].map { |_team| reviewer["slug"] }

        github_users.map { |github_user| get_user_mention(params, github_user) }
      end

      def self.get_user_mention(params, github_user)
        github_user_mentions = Helper::GithubUsersAndMentionsHelper.parse_github_users_and_mentions(params[:github_users_and_mentions])
        github_user_mentions[github_user] || github_user
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generates message data for several GitHub Actions' pull request events"
      end

      def self.details
        "The action generates a Markdown message and payload with data related to PR events triggered in a GitHub Action.\n"\
        "* The currently handled GitHub Actions events handled are: `pull_request` and `pull_request_review`\n"\
        "* The currently handled `pull_request` actions are: `opened`, `closed`\n"\
        "* The currently handled `pull_request_review` actions are: every action should be compatible\n"\
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :context,
            env_name: "FL_GITHUB_CONTEXT",
            description:
             "The GitHub Actions context."\
             "You must pass it to Fastlane with `${{ toJson(github) }}` in a GitHub action environment variable",
            is_string: true,
            optional: true,
            default_value: ENV["GITHUB_CONTEXT"]),
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
          ["GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_NAME",
           "The name of the triggered pull request event",],
          ["GITHUB_PULL_REQUEST_NOTIFIER_GITHUB_EVENT_ACTION",
           "The name of the triggered pull request event action",],
        ]
      end

      def self.return_type
        # Check https://github.com/fastlane/fastlane/blob/0d1aa50045d57975d8b9e5d5f1f489d82ee0f437/fastlane/lib/fastlane/action.rb#L23
        # for available types
        :hash
      end

      def self.return_value
        "The pull request event message and payload hash in Markdown format"
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
            notification = github_pull_request_notifier(
              github_context: ENV["GITHUB_CONTEXT"],
              github_users_and_mentions: "github_user_1:your_messaging_system_mention,github_user_2:your_messaging_system_mention"
            )
            puts "The notification message is: #{notification.message}, the payload is: #{notification.payload}"
            ',
          '
            # You have helper functions for formatting mentions for Slack and Webex
            slack_notification = github_pull_request_notifier(
              github_context: ENV["GITHUB_CONTEXT"],
              github_users_and_mentions: Actions.get_github_user_login_mention_for_slack("my_github_user", "my_slack_handle")
            )
            slack(message: slack_notification.message, payload: slack_notification.payload)

            webex_notification = github_pull_request_notifier(
              github_context: ENV["GITHUB_CONTEXT"],
              github_users_and_mentions: Actions.get_github_user_login_mention_for_webex("my_github_user", "my_webex_user@email.com")
            )
            webex(message: webex_notification.message, payload: webex_notification.payload)
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
