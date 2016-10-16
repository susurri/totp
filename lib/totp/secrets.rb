require 'yaml'
require 'io/console'
require 'openssl'
require 'rotp'
require 'totp/window'

module Totp
  # handle encrypted secrets store
  class Secrets
    def initialize(filename)
      @filename = filename
      @secrets = []
      @totp = {}
      @encryption = nil
      @window = Window.new
    end

    def add(entry)
      load
      list
      return if dup?(entry)
      @secrets.reject! { |secret| secret[:id] == entry[:id] }
      @secrets.push(entry)
      save
    end

    def remove(id)
      load
      list
      @secrets.reject! { |secret| secret[:id] == id }
      save
    end

    def list
      load
      @secrets.each do |secret|
        puts secret[:id]
      end
    end

    def print
      load
      init_totp
      @window.init_curses
      loop do
        @window.show_curses(@secrets, @totp)
        break if @window.getch
      end
    ensure
      @window.close
    end

    private

    def init_totp
      @secrets.each do |secret|
        @totp[secret[:id]] = ROTP::TOTP.new(secret[:secret])
      end
    end

    def dup?(entry)
      dup = @secrets.select { |secret| secret[:id] == entry[:id] }
      return false if dup.empty?
      STDOUT.print 'replace ' + entry[:id] + '? y/[n] '
      return false if /^[yY]/ =~ STDIN.gets
      true
    end

    def passphrase
      STDOUT.print 'Passphrase: '
      pass = STDIN.noecho(&:gets)
      puts
      pass
    end

    def encrypt(data)
      cipher = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
      salt = OpenSSL::Random.random_bytes(8)
      cipher.encrypt
      cipher.pkcs5_keyivgen(@passphrase, salt)
      encrypted_data = cipher.update(data) + cipher.final
      'Salted__' + salt + encrypted_data
    end

    def decrypt(data)
      data = data.force_encoding('ASCII-8BIT')
      salt = data[8, 8]
      data = data[16, data.size]
      cipher = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
      cipher.decrypt
      cipher.pkcs5_keyivgen(@passphrase, salt)
      cipher.update(data) + cipher.final
    end

    def load
      return unless File.exist?(@filename)
      @passphrase = passphrase
      f = File.open(@filename, 'rb')
      @secrets = YAML.load(decrypt(f.read))
      f.close
    end

    def save
      f = File.open(@filename, 'wb')
      f.write(encrypt(YAML.dump(@secrets)))
      f.close
    end
  end
end
