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
          hash = lookup(id) || @keys[id]
          raise KeyNotFound, 'Ensure all secret keys are loaded with `HMAC::KeyCabinet.add_key`' if hash.nil?
          OpenStruct.new(hash)
        end

        def lookup(id)
          return unless @lookup_block
          if key = @lookup_block.call(id)
            return { id: id, auth_key: key }
          end
        end

        def lookup_block=(block)
          @lookup_block = block
        end
      end
    end
  end
end
