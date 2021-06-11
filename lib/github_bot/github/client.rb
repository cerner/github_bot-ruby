# frozen_string_literal: true

require 'octokit'
require 'uri'
require_relative 'payload'

module GithubBot
  module Github
    # Public: The Client class manages the client interactions with GitHub
    # such as file retrieval, pull request comments, and pull request checks
    class Client
      # include the payload attributes
      include GithubBot::Github::Payload
      FILE_REMOVED_STATUS = 'removed'
      RAW_TYPE = 'application/vnd.github.v3.raw'

      class << self
        # Public: Initialize the singleton with the incoming request information
        #
        # @param request [Object] The incoming request payload
        def initialize(request)
          @instance = new(request)
        end

        # Public: Returns the current instance of the Client
        #
        # @raise [StandardError] Raises error if instance has not been initialized before usage
        def instance
          raise StandardError, 'client not initialize' unless @instance

          @instance
        end
      end

      # Public: Creates a new instance of the Client to manage the GitHub api transactions
      #
      # @param request [Object] The incoming request payload
      def initialize(request)
        @request = request
      end

      # Public: Retrieve the contents of a file
      #
      # @param file [Sawyer::Resource] The file for retrieving contents
      def file_content(file)
        raw_contents file
      rescue Octokit::NotFound
        ''
      rescue Octokit::Forbidden => e
        if e.errors.any? && e.errors.first[:code] == 'too_large'
          # revert to using the raw_url for getting the content
          return URI.parse(file.raw_url).open.read
        end

        raise e
      end

      # Public: Return the modified files, excluding those that have been removed, from the pull request
      #
      # @return [Array<Sawyer::Resource>] A list of modified files impacted with the current pull request
      def modified_files
        files.reject do |github_file|
          github_file.status == FILE_REMOVED_STATUS
        end
      end

      # Public: Returns an array of all the files impacted with the current pull request
      #
      # @return [Array<Sawyer::Resource>] A list of all files impacted with the current pull request
      def files
        return [] if pull_request.nil?

        @files ||= client.pull_request_files(repository_full_name, pull_request_number)
      end

      # Public: Added a comment to the existing pull request
      #
      # @param opts [Hash] The parameter options for adding a comment
      # @option opts [:symbol] :message The message to add to the pull request
      def comment(message:, **opts)
        client.add_comment(repository_full_name, pull_request_number, message, **opts)
      end

      # Public: Creates a GitHub check run for execution
      #
      # @return [GithubBot::Github::CheckRun] The created check run
      def create_check_run(name:, **opts)
        CheckRun.new(
          name: name,
          repo: repository_full_name,
          sha: head_sha,
          client_api: client,
          **opts
        )
      end

      # Public: Returns a GitHub pull request object with the details of the current request
      #
      # @return [Sawyer::Resource] The pull request details associated to current request
      def pull_request_details
        @pull_request_details ||= client.pull_request(repository[:full_name], pull_request[:number])
      end

      # Public: Returns the current list of pull request reviewers
      #
      # @return [Array<Sawyer::Resource>] The list of current pull request reviewers
      def pull_request_reviewers
        @pull_request_reviewers ||= client.pull_request_reviews(
          repository[:full_name],
          pull_request[:number]
        ).sort_by(&:submitted_at)
      end

      # Public: Returns the current list of approving pull request reviewers
      #
      # @return [Array<Sawyer::Resource>] The list of approving pull request reviewers
      def approving_reviewers
        pull_request_reviewers.select { |r| r.state == 'APPROVED' }
      end

      # Public: Returns the current list of request comments
      #
      # @return [Array<Sawyer::Resource>] The list of pull request comments
      def pull_request_comments
        @pull_request_comments ||= client.issue_comments(
          repository[:full_name],
          pull_request[:number]
        ).sort_by(&:created_at)
      end

      private

      # Decode the content retrieved from GitHub
      #
      # @param content [Sawyer::Resource] The content returned from GitHub to decode
      # @return [String] Returns the Base64-decoded version of the content
      def decode(content)
        content&.content ? Base64.decode64(content.content).force_encoding('UTF-8') : ''
      end

      # Decode the contents of the file
      def decode_contents(file)
        decode(client.contents(repository_full_name, path: file.filename, ref: head_sha))
      end

      # Get raw contents from passed file
      def raw_contents(file)
        client.contents(repository_full_name, path: file.filename, ref: head_sha, headers: { 'Accept': RAW_TYPE })
      end

      # Returns an instance of the GitHub client API to utilize
      def client
        @client ||= Octokit::Client.new(access_token: installation_access_token, auto_paginate: true)
      end

      # Gets an access token associated to the request
      def installation_access_token
        Octokit::Client.new(bearer_token: private_key).create_installation_access_token(installation_id)[:token]
      end

      # Gets the private key associated to the GitHub application
      def private_key
        private_pem =
          if ENV['GITHUB_APP_PEM_PATH']
            File.read(Rails.root.join(ENV['GITHUB_APP_PEM_PATH']))
          elsif ENV['GITHUB_APP_PEM_V2']
            ENV['GITHUB_APP_PEM_V2'].gsub('\\\n', "\n")
          elsif ENV['GITHUB_APP_PEM']
            ENV['GITHUB_APP_PEM'].gsub('\n', "\n")
          else
            raise StandardError, "'GITHUB_APP_PEM_PATH' or 'GITHUB_APP_PEM' needs to be set"
          end

        private_key = OpenSSL::PKey::RSA.new(private_pem)

        current = Time.current.to_i

        payload = {
          iat: current,
          exp: current + (10 * 60),
          iss: ENV['GITHUB_APP_IDENTIFIER']
        }
        JWT.encode(payload, private_key, 'RS256')
      end

      # relay messages to Octokit::Client if responds to allow extension
      # of the client and extend/overwrite those concerned with
      def method_missing(method, *args, &block)
        return super unless respond_to_missing?(method)

        return payload[method] if payload.key?(method)

        client.send(method, *args, &block)
      end

      # because tasks are executed by a validator, some methods are relayed across
      # from the task back to the validator.  this override checks for that existence
      def respond_to_missing?(method, *args)
        payload.key?(method) || client.respond_to?(method, *args)
      end
    end
  end
end
