# frozen_string_literal: true

module GithubBot
  # Public: A request helper for understanding the incoming request context
  module GithubRequestHelper
    # Public: Returns the GitHub event type of the incoming request
    def github_event
      request.env['HTTP_X_GITHUB_EVENT']
    end

    # Public: Returns if the GitHub signature of the incoming request
    def github_signature
      request.env['HTTP_X_HUB_SIGNATURE'] || 'no-signature'
    end

    # Public: Returns the raw content of the github payload's body content
    def github_payload_raw
      @github_payload_raw ||= request.body.read
    end

    # Public: Returns the <Json> representation of the github payload
    def github_payload
      return @github_payload if @github_payload

      begin
        @github_payload = JSON.parse(github_payload_raw).with_indifferent_access
      rescue StandardError => e
        raise StandardError, "Invalid JSON (#{e}): #{@github_payload_raw}"
      end
    end

    # Public: Returns <true> if the event type is of type 'ping'; otherwise, <false>
    def ping?
      github_event == 'ping'
    end

    # Public: Return <true> if the event type is of type 'pull_request'; otherwise, <false>
    def pull_request?
      github_event == 'pull_request'
    end

    # Public: Return <true> if the event type is of type 'pull_request_review'; otherwise, <false>
    def pull_request_review?
      github_event == 'pull_request_review'
    end

    # Public: Return <true> if the event type is of type 'check_run'; otherwise, <false>
    def check_run?
      github_event == 'check_run'
    end

    # Public: Return <true> if the action type is of type 'review_requested'; otherwise, <false>
    def review_requested?
      github_event == 'review_requested'
    end

    # Public: Return <true> if the action type is of type 'review_request_removed'; otherwise, <false>
    def review_request_removed?
      github_event == 'review_request_removed'
    end

    # Public: Return <true> if the action type is of type 'labeled'; otherwise, <false>
    def labeled?
      github_event == 'labeled'
    end

    # Public: Return <true> if the action type is of type 'issue_comment'; otherwise, <false>
    def issue_comment?
      github_event == 'issue_comment'
    end

    # Public: Returns <String> of the comment's body from the github payload
    def comment_body
      github_payload['comment']['body']
    end

    # Public: Return <true> if the action type is of type 'issue_comment'
    # and the comment message contains "run_validation"; otherwise, <false>
    def issue_comment_recheck?
      github_event == 'issue_comment' && comment_body.include?('run_validation')
    end

    # Public: Return <true> if issue_comment_recheck? is true
    # and the comment message contains option; otherwise, <false>
    #
    # @param [String] option represents which validation to run
    def recheck_application?(option)
      return false unless issue_comment_recheck?

      options = recheck_options(comment_body)
      options.include?(option) || options.include?('all')
    end

    # Public: Return <true> if the action type is of type 'unlabeled'; otherwise, <false>
    def unlabeled?
      github_event == 'unlabeled'
    end

    # Public: Returns the pull request action type from the payload
    def pull_request_action
      github_payload['action']
    end

    # Public: Returns the pull request content from the payload
    def pull_request
      github_payload['pull_request']
    end

    # Public: Returns the repository payload
    def repository
      github_payload['repository']
    end

    private

    # Private: Return an array of strings
    #
    # @param str input like "run_validation: a, b, c" with return of ["a","b","c"]
    def recheck_options(str)
      str.gsub(/\s+/, '').partition(':').last.split(',')
    end
  end
end
