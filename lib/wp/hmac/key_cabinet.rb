module WP
  module HMAC
    # = Key Cabinet
    #
    # Stores the secret keys used in the hash function.
    class KeyCabinet
      class KeyNotFound < Exception; end

      class << self
        attr_accessor :keys
        attr_writer :lookup_block

        def add_key(id:, auth_key:)
          @keys ||= {}
          @keys[id] = { id: id, auth_key: auth_key }
        end

        # This method will be called by EY::ApiHMAC. It must return
        # an object that responds to +id+ and +auth_key+
        def find_by_auth_id(id)
          hash = lookup(id) || @keys[id]
          msg = 'Ensure secret keys are loaded with `HMAC::KeyCabinet.add_key`'
          fail KeyNotFound, msg if hash.nil?
          OpenStruct.new(hash)
        end

        def lookup(id)
          return unless @lookup_block
          key = @lookup_block.call(id)
          return { id: id, auth_key: key } if key
        end
      end
    end
  end
end
