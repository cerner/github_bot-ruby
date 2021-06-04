# frozen_string_literal: true

module GithubBot
  module Tasks
    class Base
      # Public: Returns the validator associated to the task execution
      attr_reader :validator

      # Public: Initialize the task from a specific validator
      #
      # @param validator [GithubBot::Validator::Base] An instance of the validator that is asking for the task
      def initialize(validator)
        @validator = validator
      end

      private

      # because tasks are executed by a validator, some methods are relayed across
      # from the task back to the validator.  this override checks for that existence
      def method_missing(method, *args, &block)
        return super unless respond_to_missing?(method)

        @validator.send(method, *args, &block)
      end

      # because tasks are executed by a validator, some methods are relayed across
      # from the task back to the validator.  this override checks for that existence
      def respond_to_missing?(method, *args)
        @validator.respond_to?(method, *args)
      end

      # returns the github client api established either by the task or the validator
      def client_api
        # evaluate if the validator has defined the api and delegate accordingly
        return validator.client_api if validator.respond_to?(:client_api)

        ::GithubBot::Github::Client.instance
      end
    end
  end
end
