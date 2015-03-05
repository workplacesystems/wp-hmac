module WP
  module HMAC
    class Client
      def initialize(url = nil, app = Rack::Client::Handler::NetHTTP)
        build_rack_client(url, app)
      end

      def build_rack_client(url, app)
        id = key_cabinet.id
        auth_key = key_cabinet.auth_key

        @client = Rack::Client.new(url) do
          use Rack::Config do |env|
            env['HTTP_DATE'] = Time.now.httpdate
          end
          use EY::ApiHMAC::ApiAuth::Client, id, auth_key
          run app
        end
        @client
      end

      def method_missing(method_missing, *args, &block)
        @client.send(method_missing, *args, &block)
      end

      def key_cabinet
        @key_cabinet ||= HMAC::KeyCabinet.find_by_auth_id(HMAC.auth_id)
      end

      class << self
        %i(delete get head options post put).each do |method|
          define_method(method) do |*args|
            client = Client.new
            client.send(method, *args)
          end
        end
      end
    end
  end
end
