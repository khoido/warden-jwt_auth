# frozen_string_literal: true

module Warden
  module JWTAuth
    class Middleware
      # Revokes a token if it path and method match with configured
      class RevocationManager < Middleware
        # Debugging key added to `env`
        ENV_KEY = 'warden-jwt_auth.revocation_manager'

        attr_reader :app, :config, :helper

        def initialize(app)
          @app = app
          @config = JWTAuth.config
          @helper = EnvHelper
        end

        def call(env)
          env[ENV_KEY] = true
          response = app.call(env)
          revoke_token(env)
          response
        end

        private

        def revoke_token(env)
          token = HeaderParser.from_env(env)
          path_info = EnvHelper.path_info(env)
          method = EnvHelper.request_method(env)
          params = EnvHelper.request_params(env) || {}
          return unless token && token_should_be_revoked?(path_info, method, params)

          TokenRevoker.new.call(token)
        end

        def token_should_be_revoked?(path_info, method, params)
          revocation_requests = config.revocation_requests
          revocation_requests.each do |tuple|
            revocation_method, revocation_path, operation_name = tuple
            return true if path_info.match(revocation_path) &&
                           method == revocation_method &&
                           params['operationName'] == operation_name
          end
          false
        end
      end
    end
  end
end
