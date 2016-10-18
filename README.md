# Totpc

totpc is an application for Two-factor authentication (2FA) with Time-Based
One-Time Password (TOTP) like google or github.
It stores id/key pairs in the encrypted file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'totpc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install totpc

## Usage

Commands:  
  totpc add             # add secret.  
  totpc chpass          # change passphrase  
  totpc help [COMMAND]  # Describe available commands or one specific command  
  totpc list            # list IDs  
  totpc print           # print totp codes.  
  totpc remove          # remove secret.  

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec totpc` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/susurri/totpc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

