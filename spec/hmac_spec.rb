ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../lib/wp/hmac', __FILE__)
require File.expand_path('../app/config/environment', __FILE__)
require 'pry'

RSpec.configure do |config|
  config.include Rack::Test::Methods, type: :request
end

class DummyController < ActionController::Base
  def create
    head :bad_request
  end

  def update
    render inline: 'Hello, updated world!'
  end

  def show
    render inline: 'Hello, world!'
  end
end

RSpec.describe WP::HMAC, type: :request do
  let(:app) { App::Application }
  let(:hmac_client) { WP::HMAC::Client.new(nil) }

  before(:example) do
    WP::HMAC.configure do
      add_hmac_enabled_route %r{^/dummy/}
      get_auth_id_for_request -> { 'esso' }
    end

    WP::HMAC::Client.rack_app = app

    Rails.application.routes.draw do
      resources :dummy
    end
  end

  after(:example) do
    WP::HMAC.reset
    Rails.application.reload_routes!
  end

  context 'with no key' do
    context 'when hmac is enabled for the route' do
      it 'raises an exception' do
        expect do
          get 'http://esso.example.com/dummy/1'
        end.to raise_error(WP::HMAC::KeyCabinet::KeyNotFound)
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

    before(:example) do
      WP::HMAC.configure do
        add_key(id: 'esso', auth_key: 'secret_key')
      end
    end

    it 'fails when a request is not signed' do
      get 'http://esso.example.org/dummy/1'

      expect(last_response.body)
        .to eql('Authentication failure: no authorization header')
    end

    it 'fails when a request is signed with a duff hash' do
      header 'Authorization', 'AuthHMAC esso:1234'
      header 'Date', Time.now.httpdate
      get 'http://esso.example.org/dummy/1'

      expect(last_response.body)
        .to include('Authentication failure: signature mismatch')
    end

    it 'succeeds when the request is correctly signed' do
      rack_response = hmac_client.get 'http://esso.example.org/dummy/1'
      expect(rack_response.body).to include('Hello, world!')
    end

    it 'succeeds when the request is correctly signed (alt syntax)' do
      rack_response = WP::HMAC::Client.get('http://esso.example.org/dummy/1')
      expect(rack_response.body).to include('Hello, world!')
    end

    it 'raises UnsuccessfulResponse when server reponds 400' do
      expect do
        hmac_client.post('http://esso.example.org/dummy')
      end.to raise_error(WP::HMAC::Client::UnsuccessfulResponse)
    end

    it 'raises UnsuccessfulResponse when server reponds 400 (alt syntax)' do
      expect do
        WP::HMAC::Client.post('http://esso.example.org/dummy')
      end.to raise_error(WP::HMAC::Client::UnsuccessfulResponse)
    end

    it 'succeeds when the request body resonds to #read' do
      rack_response = hmac_client.put('http://esso.example.org/dummy/1',
                                      {},
                                      StringIO.new('hi'))

      expect(rack_response.body).to include('Hello, updated world!')
    end

    it 'succeeds when the request body is a string' do
      rack_response = hmac_client.put('http://esso.example.org/dummy/1',
                                      {},
                                      'hi')

      expect(rack_response.body).to include('Hello, updated world!')
    end

    context 'with a key configured via a block' do
      before do
        WP::HMAC.configure do
          lookup_auth_key_with { |id| id == 'account2' ? 'mykey' : nil }
        end
      end

      it 'looks up the key via the block' do
        key = WP::HMAC::KeyCabinet.find_by_auth_id('account2')
        expect(key.auth_key).to eq 'mykey'
      end

      it 'still finds keys from the add_key method' do
        key = WP::HMAC::KeyCabinet.find_by_auth_id('esso')
        expect(key.auth_key).to eq 'secret_key'
      end
    end
  end
end
