module WP
  module HMAC
    class KeyCabinet
      class KeyNotFound < Exception; end

      class << self
        attr_accessor :keys

        def add_key(id:, auth_key:)
          @keys ||= {}
          @keys[id] = { id: id, auth_key: auth_key }
        end

        def find_by_auth_id(id)
          key = @keys[id]
          raise KeyNotFound, 'Ensure all secret keys are loaded with `HMAC::KeyCabinet.add_key`' if key.nil?
          OpenStruct.new(key)
        end
      end
    end
  end
end
