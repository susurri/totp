require 'thor'

module Totp
  # command line interpreter
  class CLI < Thor
    desc 'print', 'print totp codes.'
    def print
    end
    desc 'add', 'add secret.'
    def add
      STDOUT.print 'id: '
      id = STDIN.gets.chomp
      STDOUT.print 'secret: '
      secret = STDIN.gets.chomp
    end
  end
end
