# Wp::Hmac

This gem wraps EY::ApiHMAC and attempts to make it easy to:
  - Enable HMAC for specific routes in your Rack application.
  - Add different secret keys for different customers, servers, routes or users.

It works with Rack applications like Ruby on Rails.

You should also consider using
[ey_api_hmac](https://github.com/engineyard/ey_api_hmac) directly, especially
if you only have one secret key or want HMAC enabled for every request.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wp-hmac'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wp-hmac

## Usage

### Configuration

You need to:

1. Add at least one key
1. Add at least one regex to match routes that will require HMAC
1. Provide a mechanism to ascertain the correct key to use (via `get_auth_id_for_request`)

``` ruby
WP::HMAC.configure do
  add_key(id: 'esso', auth_key: key['auth_key'])
  add_key(id: 'texaco', auth_key: 'super_secr3t_key'])

  add_hmac_enabled_route %r{^/texaco-api/}
  add_hmac_enabled_route %r{^/esso-api/}

  # This will be used by both the Server and Client
  # in this `CurrentCustomer.name` returns either 'esso' or 'texaco'
  #
  # This method must be available at the Rack layer and wherever you
  # use the client.
  get_auth_id_for_request -> { CurrentCustomer.name }
end
```

You then need to slot the middleware into your rack stack. For Rails:

``` ruby
use WP::HMAC::Server
```

### Using the client

Use like this ...
``` ruby
   WP::HMAC::Client.get('https://www.example.com/api/staff')
   WP::HMAC::Client.post('https://www.example.com/api/schedules, {'HEADER' => 'foo'}, StringIO.new('data'))
```
 ... or like this:
``` ruby
   client = WP::HMAC::Client.new('https://www.example.com')
   client.get('api/staff')
   client.post('api/schedules', {}, StringIO.new('data'))
```
See Rack::Client docs for more.

## Testing

You can use the client and server to test at the Rack layer without transporting over HTTP. See the `spec/hmac_spec.rb` for the detail.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/wp-hmac/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Thanks

Many thanks to [Engine Yard](https://github.com/engineyard) for [https://github.com/engineyard/ey_api_hmac](Engine Yard HMAC api implementation).
