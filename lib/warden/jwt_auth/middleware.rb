# frozen_string_literal: true

require 'warden/jwt_auth/middleware/token_dispatcher'
require 'warden/jwt_auth/middleware/revocation_manager'

module Warden
  module JWTAuth
    # Calls two actual middlewares
    class Middleware
      attr_reader :app, :config

      def initialize(app)
        @app = app
        @config = JWTAuth.config
      end

      def call(env)
        builder = Rack::Builder.new(app)
        builder.use(RevocationManager, config)
        builder.use(TokenDispatcher, config)
        builder.run(app)
        builder.call(env)
      end
    end
  end
end
