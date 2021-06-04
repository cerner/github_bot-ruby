# frozen_string_literal: true

module GithubBot
  module Response
    # Public: Renders a json response
    def json_response(object, status = :ok)
      render json: object, status: status
    end

    # Public: Returns a json response indicating a 404
    def json_not_found(params)
      {
        errors: {
          message: "Not found with parameter #{params}"
        }
      }
    end

    # Public: Returns a json response indicating a 403
    def json_access_denied(**args)
      { errors: 'access denied' }.merge(args)
    end
  end
end
