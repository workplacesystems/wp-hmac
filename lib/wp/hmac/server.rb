module WP
  module HMAC
    # = HMAC Server
    #
    # Authenticate a request using EY::ApiHMAC
    class Server
      @hmac_enabled_routes = []

      class << self
        attr_accessor :hmac_enabled_routes
      end

      def initialize(app)
        @app = app
        @hmac_auth = EY::ApiHMAC::ApiAuth::Server.new(app, HMAC::KeyCabinet)
      end

      def call(env)
        if hmac_enabled_route?(env)
          verify_key!
          @hmac_auth.call(env)
        else
          @app.call(env)
        end
      end

      def verify_key!
        KeyCabinet.find_by_auth_id(id_for_request)
      end

      def id_for_request
        HMAC.auth_id
      end

      private

      def hmac_enabled_route?(env)
        Server.hmac_enabled_routes.any? { |r| env['PATH_INFO'].match(r) }
      end
    end
  end
end
