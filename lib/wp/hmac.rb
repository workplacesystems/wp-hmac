require "wp/hmac/version"
require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'rack/client'
require 'ey_api_hmac'

require File.expand_path('../hmac/server', __FILE__)
require File.expand_path('../hmac/client', __FILE__)
require File.expand_path('../hmac/key_cabinet', __FILE__)

module WP
  module HMAC
    class MissingConfiguration < StandardError; end

    def self.configure(&block)
      instance_eval(&block)
    end

    def self.add_key(id:, auth_key:)
      KeyCabinet.add_key( { id: id, auth_key: auth_key } )
    end

    def self.add_hmac_enabled_route(route_regex)
      Server.hmac_enabled_routes << route_regex
    end

    def self.get_auth_id_for_request(callable)
      @callable = callable
    end

    def self.auth_id
      raise MissingConfiguration('Set get_auth_id_for_request in the initializer') unless @callable
      @callable.call
    end

    def self.reset
      KeyCabinet.keys = {}
      Server.hmac_enabled_routes = []
    end
  end
end
