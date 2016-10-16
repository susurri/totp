require 'thor'
require 'totp/secrets'

module Totp
  # command line interpreter
  class CLI < Thor
    def initialize(args, local_options, config)
      @secrets = Secrets.new(Dir.home + '/.totp')
      super(args, local_options, config)
    end
    desc 'print', 'print totp codes.'
    def print
      @secrets.print
    end
    desc 'add', 'add secret.'
    def add
      STDOUT.print 'id: '
      id = STDIN.gets.chomp
      STDOUT.print 'secret: '
      secret = STDIN.gets.chomp
      @secrets.add(id: id, secret: secret)
    end
    desc 'remove', 'remove secret.'
    def remove
      STDOUT.print 'id: '
      id = STDIN.gets.chomp
      STDOUT.print 'remove ' + id + '? y/[n] '
      @secrets.remove(id) if /^[yY]/ =~ STDIN.gets
    end
    desc 'list', 'list IDs'
    def list
      @secrets.list
    end
  end
end
