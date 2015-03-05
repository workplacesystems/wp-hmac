ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../lib/wp/hmac', __FILE__)
require File.expand_path('../app/config/environment', __FILE__)
require 'pry'

RSpec.configure do |config|
  config.include Rack::Test::Methods, type: :request
end

class DummyController < ActionController::Base
  def show
    render inline: 'Hello, world!'
  end
end

RSpec.describe WP::HMAC, type: :request do
  before(:example) do
    WP::HMAC.configure do
      add_key( { id: 'esso', auth_key: 'secret_key' } )
      add_hmac_enabled_route %r{^/dummy/}
      get_auth_id_for_request -> { 'esso' }
    end
  end

  after(:example) do
    WP::HMAC.reset
  end

  let(:app) { App::Application }
  let(:hmac_client) { WP::HMAC::Client.new(nil, app) }

  before do
    Rails.application.routes.draw do
      resources :dummy, only: %i(show)
    end
  end

  after do
    Rails.application.reload_routes!
  end

  context 'with no key' do
    before(:each) do
      WP::HMAC::KeyCabinet.instance_eval('@keys = {}')
    end

    context 'when hmac is enabled for the route' do
      it 'raises an exception' do
        expect {
          get 'http://esso.example.com/dummy/1'
        }.to raise_error(WP::HMAC::KeyCabinet::KeyNotFound)
      end
    end

    context 'when hmac is not enabled for the route' do
      it 'has no effect' do
        WP::HMAC::Server.hmac_enabled_routes = []
        get 'http://esso.example.com/dummy/1'
        expect(last_response.body).to eql('Hello, world!')
      end
    end
  end

  context 'with a key cabinet' do
    it 'fails when a request is not signed' do
      get 'http://esso.example.org/dummy/1'
      expect(last_response.body).to eql('Authentication failure: no authorization header')
    end

    it 'fails when a request is signed with a duff hash' do
      header 'Authorization', 'AuthHMAC esso:1234'
      header 'Date', Time.now.httpdate
      get 'http://esso.example.org/dummy/1'
      expect(last_response.body).to include('Authentication failure: signature mismatch')
    end

    it 'succeeds when the request is correctly signed' do
      rack_response = hmac_client.get 'http://esso.example.org/dummy/1'
      expect(rack_response.body).to include('Hello, world!')
    end
  end
end
