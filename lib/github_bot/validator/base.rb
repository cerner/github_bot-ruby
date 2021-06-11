# frozen_string_literal: true

module GithubBot
  module Validator
    # Public: Base class for validators to extend to provide helpful
    # methods for interactions with GitHub
    class Base
      class << self
        # Public: Validation method that every consumer will need to override
        def validate; end
      end

      # Public: Initializes an instance of the validator
      def initialize
        @feedback = []
        @check = nil
      end

      # Public: Provide feedback to be generated upon completion of the check run
      # see https://docs.github.com/en/rest/reference/checks#create-a-check-run for additional
      # details on available parameters for the 'annotations' item
      def feedback(path:, start_line: 0, end_line: 0, annotation_level:, message:, **opts)
        @feedback << {
          path: path,
          start_line: start_line,
          end_line: end_line,
          annotation_level: annotation_level,
          message: message,
          **opts
        }
      end

      # Public: Moves the check run into the in progress status
      def in_progress(**opts)
        raise StandardError, 'check run has not been established' unless @check

        defaults = {
          output: {
            title: "#{@check.name} validation is in progress...",
            summary: 'We\'re currently validating this request. Please stand by.'
          }
        }

        @check.in_progress!(defaults.deep_merge(opts))
      end

      # Public: Block for execution logic that is the be evaluated and finalized
      # within the GitHub check run content
      def check_run(name:, **_opts)
        # queue request for processing
        @check = client_api.create_check_run(
          name: name,
          output: {
            title: "#{name} validation has been queued...",
            summary: "We're awaiting processing."
          }
        )

        yield if block_given?

        if @feedback.empty?
          @check.complete!(
            output: {
              title: "#{name} validation is complete...",
              summary: "#{name} validation passed!"
            }
          )

        else
          # because limitation of 50 checks per API call execution, break up annotations
          # https://developer.github.com/v3/checks/runs/
          @feedback.each_slice(50).to_a.each do |annotations|
            @check.action_required!(
              output: {
                title: "#{name} validation is complete...",
                summary: "#{name} validation determined there are changes that need attention.",
                annotations: annotations
              }
            )
          end
        end
      rescue StandardError => e
        Rails.logger.error message: 'Error occurred during check run', exception: e
        @check.action_required!(
          output: {
            title: "#{name} validation failed...",
            summary: "# Message\n```\n#{e.message}\n```\n# Exception\n```\n#{e.backtrace.join("\n")}\n```"
          }
        )
      end

      # Public: Return all files from request.
      def files
        client_api.files
      end

      # Public: Return the modified files from request.
      def modified_files
        client_api.modified_files
      end

      # Public: Validates the file extension for the provided file
      #
      # @param file [Sawyer::Resource] The file to evaluate
      # @param extension [String] The extension type to evaluate
      def validate_file_extension(file, extension)
        return if File.extname(file.filename) == ".#{extension}"

        feedback(
          path: file.filename,
          annotation_level: 'failure',
          message: "File suffix is incorrect, please use '.#{extension}'"
        )
      end

      # Public: Loads the yaml of the file provided
      #
      # @param file [Sawyer::Resource] The file to load
      def load_yaml(file)
        YAML.safe_load(client_api.file_content(file)).with_indifferent_access
      rescue StandardError => e
        feedback(
          path: file.filename,
          annotation_level: 'failure',
          message: 'Malformed yaml content'\
                   "exception: #{e.message}"
        )

        {}
      end

      # Public: Validates for the provided file at a given hash point that the
      # required and allowed fields are met
      #
      # @param file [Sawyer::Resource] The file for reference that is being evaluated
      # @param ident [String/Symbol] The text identifier for the hash being evaluated
      # @param hash [Hash] The hash to review keys
      # @param required_fields [Array] An array of required elements
      # @param allowed_fields [Array] An array of allowed fields
      def validate_fields(file:, ident:, hash:, required_fields:, allowed_fields:, **opts)
        unless hash
          feedback(
            path: file.filename,
            annotation_level: 'failure',
            message: 'Element is empty or nil'
          )

          return
        end

        validate_required_fields(
          file: file,
          ident: ident,
          hash: hash,
          required_fields: required_fields,
          **opts
        )
        validate_allowed_fields(
          file: file,
          ident: ident,
          hash: hash,
          allowed_fields: allowed_fields,
          **opts
        )
      end

      # Public: Validates for the provided file at a given hash point that the
      # required fields are met
      #
      # @param file [Sawyer::Resource] The file for reference that is being evaluated
      # @param ident [String/Symbol] The text identifier for the hash being evaluated
      # @param hash [Hash] The hash to review keys
      # @param required_fields [Array] An array of required elements
      def validate_required_fields(file:, ident:, hash:, required_fields:, **_opts)
        unless hash
          feedback(
            path: file.filename,
            annotation_level: 'failure',
            message: "#{ident}: Element is empty or nil"
          )

          return
        end

        required_fields.each do |key|
          next unless hash[key].nil?

          feedback(
            path: file.filename,
            annotation_level: 'failure',
            message: "#{ident}: Missing required element '#{key}'"
          )
        end
      end

      # Public: Validates for the provided file at a given hash point that the
      # allowed fields are met
      #
      # @param file [Sawyer::Resource] The file for reference that is being evaluated
      # @param ident [String/Symbol] The text identifier for the hash being evaluated
      # @param hash [Hash] The hash to review keys
      # @param allowed_fields [Array] An array of allowed fields
      def validate_allowed_fields(file:, ident:, hash:, allowed_fields:, **_opts)
        unless hash
          feedback(
            path: file.filename,
            annotation_level: 'failure',
            message: "#{ident}: Element is empty or nil"
          )

          return
        end

        hash.keys&.each do |key|
          unless allowed_fields.include?(key)
            feedback(
              path: file.filename,
              annotation_level: 'failure',
              message: "#{ident}: Key '#{key}' not in the allowed fields [#{allowed_fields.join(', ')}]"
            )
          end
        end
      end

      private

      def client_api
        ::GithubBot::Github::Client.instance
      end
    end
  end
end
