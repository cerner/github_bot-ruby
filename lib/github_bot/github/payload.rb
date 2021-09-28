# frozen_string_literal: true

require 'open-uri'
require 'json'
require 'yaml'

module GithubBot
  module Github
    # The GitHub webhook payload information
    # @see https://developer.github.com/webhooks/event-payloads/#webhook-payload-object-common-properties
    module Payload
      # Public: Returns the installation identifier associated to the event
      #
      # @return [Integer] identifier of the GitHub App installation
      def installation_id
        payload[:installation][:id]
      end

      # Public: Return <true> if the payload event type is of type 'pull_request'; otherwise, <false>
      def pull_request?
        payload_type == 'pull_request'
      end

      # Public: Return <true> if the payload event type is of type 'check_run'; otherwise, <false>
      def check_run?
        payload_type == 'check_run'
      end

      # Public: Return <true> if the payload event type is of type 'review_requested'; otherwise, <false>
      def review_requested?
        payload_type == 'review_requested'
      end

      # Public: Return <true> if the payload event type is of type 'review_request_removed'; otherwise, <false>
      def review_request_removed?
        payload_type == 'review_request_removed'
      end

      # Public: Return <true> if the action type is of type 'issue_comment'; otherwise, <false>
      # This is used for all other comment triggered issue_comment events
      def issue_comment?
        payload_type == 'issue_comment'
      end

      # Public: Return <true> if the payload event type is of type 'labeled'; otherwise, <false>
      def labeled?
        payload_type == 'labeled'
      end

      # Public: Return <true> if the payload event type is of type 'unlabeled'; otherwise, <false>
      def unlabeled?
        payload_type == 'unlabeled'
      end

      # Public: Return the activity related to the pull request
      #
      # @return [Hash] The activity related to the pull request
      def pull_request
        if pull_request?
          payload[:pull_request]
        elsif check_run?
          payload[:check_run][:pull_requests].first
        elsif issue_comment?
          payload[:issue]
        else
          payload.key?(:pull_request) ? payload[:pull_request] : {}
        end
      end

      # Public: Returns the review information for payloads that are of type pull request review
      def review
        payload[:review]
      end

      # Public: Returns <true> if the sender is of type 'Bot'; otherwise, <false>
      def sender_type_bot?
        payload[:sender][:type].downcase == 'bot' # rubocop:disable Performance/Casecmp
      end

      # Public: Returns the pull request number from the payload
      #
      # @return [Integer] The pull request number from the payload
      def pull_request_number
        pull_request[:number]
      end

      # Public: Returns the SHA of the most recent commit for this pull request
      #
      # @return [String] The SHA of the most recent commit for this pull request
      def head_sha
        if issue_comment?
          'HEAD'
        else
          pull_request[:head][:sha]
        end
      end

      # Public: Returns the head branch that the changes are on
      #
      # @return [String] The head branch that the changes are on
      def head_branch
        pull_request[:head][:ref]
      end

      # Public: Returns the base branch that the head was based on
      #
      # @return [String] The base branch that the head was based on
      def base_branch
        pull_request[:base][:ref]
      end

      # Public: Returns the pull request body content
      #
      # @return [String] The pull request body content
      def pull_request_body
        pull_request[:body]
      end

      # Public: Returns the name of the repository where the event was triggered
      #
      # @return [String] The name of the repository where the event was triggered
      def repository_name
        repository[:name]
      end

      # Public: Returns the organization and repository name
      #
      # @return [String] The organization and repository name
      def repository_full_name
        repository[:full_name]
      end

      # Public: Returns the repository URL utilized for performing a 'git clone'
      #
      # @return [String] The repository URL utilized for performing a 'git clone'
      def repository_clone_url
        repository[:clone_url]
      end

      # Public: Returns the repository fork URL from the original project with the most
      # recent updated forked instance first
      #
      # Utilizing API: https://docs.github.com/en/rest/reference/repos#forks
      # Example: https://api.github.com/repos/octocat/Hello-World/forks?page=1
      #
      # @return [Array] The array of [String] URLs associated to the forked repositories
      def repository_fork_urls
        return @repository_fork_urls if @repository_fork_urls

        @repository_fork_urls =
          [].tap do |ar|
            # iterate over pages of forks
            page_count = 1
            forks_url = repository[:forks_url]
            loop do
              uri = URI.parse(forks_url)
              new_query_ar = URI.decode_www_form(String(uri.query)) << ['page', page_count]
              uri.query = URI.encode_www_form(new_query_ar)

              Rails.logger.info "#{self.class}##{__method__} retrieving #{uri}"

              json = uri.open.read
              json_response = JSON.parse(json)
              break if json_response.empty?

              # iterate over each fork and capture the clone_url
              json_response.each do |fork|
                ar << fork['clone_url']
              end

              page_count += 1
            end
          end
      end

      # Public: Returns the repository default branch
      #
      # @return [String] The repository default branch
      def repository_default_branch
        repository[:default_branch]
      end

      # Public: Returns a list of class object names to create for validation
      #
      # @return [Array<String>] A list of strings associated to the class object validators
      def repository_pull_request_bots
        return @repository_pull_request_bots if @repository_pull_request_bots

        file = raw_file_url('.github-bots')
        @repository_pull_request_bots = [].tap do |ar|
          if file
            resp = YAML.safe_load(URI.parse(file).open.read)
            ar << resp['pull_request'] if resp['pull_request']
          end
        end.flatten
      rescue SyntaxError => e
        Rails.logger.error message: "Error parsing file '#{file}'", exception: e

        # Allow continuation of process just won't utilize any bot validations until
        # parsing error of file is corrected
        {}
      end

      private

      def method_missing(method_name, *args)
        payload[method_name] || super
      end

      def respond_to_missing?(method, *args)
        payload.key?(method) || super
      end

      def raw_file_url(path)
        # https://github.com/api/v3/repos/poloka/foo-config/contents/.github-bot?ref=
        content_file = File.join(repository_contents_url, "#{path}?ref=#{head_sha}")
        JSON.parse(URI.parse(content_file).open(&:read))['download_url']
      rescue ::OpenURI::HTTPError => e
        raise StandardError, "file '#{content_file}' not found" unless /404 Not Found/i.match?(e.message)
      end

      def repository_contents_url
        # drop the last 'path' portion of the API endpoint
        # https://github.com/api/v3/repos/poloka/foo-config/contents/{+path}
        repository[:contents_url].split('/')[0...-1].join('/')
      end

      def payload
        @payload ||= verify_webhook_signature(payload_body, @request.env['HTTP_X_HUB_SIGNATURE'])
      end

      def payload_body
        @payload_body ||= @request.body.read
      end

      def payload_type
        @request.env['HTTP_X_GITHUB_EVENT'] if @request
      end

      def verify_webhook_signature(payload, payload_signature)
        signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('sha1'),
          ENV['GITHUB_WEBHOOK_SECRET'],
          payload
        )
        Rack::Utils.secure_compare(signature, payload_signature) ? JSON.parse(payload).with_indifferent_access : false
      end
    end
  end
end
