# frozen_string_literal: true

module GithubBot
  module Github
    # Public: Class to keep track of the check run that has been created for execution
    class CheckRun
      # The name/identifier of the check run
      attr_reader :name

      # Public: Create a new instance of the CheckRun
      #
      # @params opts [Hash] A hash of options to utilized within the check run
      # @option opts [:symbol] :name The name of the check run
      # @option opts [:symbol] :repo The repository the checked run will be associated
      # @option opts [:symbol] :sha  The SHA commit for the check run to execute
      # @option opts [:symbol] :client_api The GitHub API
      def initialize(name:, repo:, sha:, client_api:, **opts)
        @client_api = client_api
        @repo = repo
        @sha = sha
        @name = name
        @run = @client_api.create_check_run(
          repo,
          name,
          sha,
          opts.merge(
            status: 'queued'
          )
        )
      end

      # Public: Updates the check run to be in progress
      def in_progress!(**options)
        update(status: 'in_progress', started_at: Time.now, **options)
      end

      # Public: Updates the check run to be complete
      def complete!(**options)
        update(status: 'completed', conclusion: 'success', completed_at: Time.now, **options)
      end

      # Public: Updates the check run to require action
      def action_required!(**options)
        update(status: 'completed', conclusion: 'action_required', completed_at: Time.now, **options)
      end

      private

      def update(**options)
        options[:accept] = Octokit::Preview::PREVIEW_TYPES[:checks]

        @client_api.update_check_run(@repo, @run.id, options)
      end
    end
  end
end
