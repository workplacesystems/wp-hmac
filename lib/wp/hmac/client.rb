module WP
  module HMAC
    class Client
      class UnsuccessfulResponse < StandardError; end

      @rack_app = Rack::Client::Handler::NetHTTP
      # Enable injection of another Rack app for testing
      class << self
        attr_accessor :rack_app
      end

      def initialize(url = nil)
        build_rack_client(url)
      end

      def build_rack_client(url)
        id = key_cabinet.id
        auth_key = key_cabinet.auth_key

        @client = Rack::Client.new(url) do
          use Rack::Config do |env|
            env['HTTP_DATE'] = Time.now.httpdate
          end
          use EY::ApiHMAC::ApiAuth::Client, id, auth_key
          run Client.rack_app
        end
        @client
      end

      def key_cabinet
        @key_cabinet ||= HMAC::KeyCabinet.find_by_auth_id(HMAC.auth_id)
      end

      # Supports:
      # client = WP::HMAC::Client.new('https://www.example.com')
      # client.get('api/staff')
      %i(delete get head options post put patch).each do |method|
        define_method(method) do |*args|
          response = @client.send(method, *args)
          raise UnsuccessfulResponse unless /2\d\d/.match("#{response.status}")
          response
        end
      end

      # Supports:
      # WP::HMAC::Client.get('https://www.example.com/api/staff')
      class << self
        %i(delete get head options post put patch).each do |method|
          define_method(method) do |*args|
            client = Client.new
            client.send(method, *args)
          end
        end
      end
    end
  end
end
