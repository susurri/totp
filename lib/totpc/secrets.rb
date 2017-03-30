require 'yaml'
require 'io/console'
require 'openssl'
require 'rotp'
require 'totpc/window'
require 'totpc/passphrase'

module Totpc
  # handle encrypted secrets store
  class Secrets
    include Passphrase
    def initialize(filename)
      @filename = filename
      @secrets = []
      @totp = {}
      @window = Window.new
    end

    def add(entry)
      load
      return if dup?(entry)
      @secrets.reject! { |secret| secret[:id] == entry[:id] }
      @secrets.push(entry)
      save
    end

    def remove(id)
      load
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

    def chpass
      load
      new_passphrase = ask_noecho('New Passphrase: ')
      new_passphrase2 = ask_noecho('New Passphrase(confirm): ')
      abort 'Passphrase does not match' if new_passphrase != new_passphrase2
      @passphrase = new_passphrase
      save
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

    def key_iv(passphrase, salt, cipher)
      digest = OpenSSL::Digest.new('sha512')
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac(passphrase, salt, 2000,
                                          cipher.key_len + cipher.iv_len,
                                          digest)
      key = key_iv[0, cipher.key_len]
      iv = key_iv[cipher.key_len, cipher.iv_len]
      [key, iv]
    end

    def encrypt(data)
      enc = OpenSSL::Cipher.new('AES-256-CBC')
      salt = OpenSSL::Random.random_bytes(8)
      enc.encrypt
      enc.key, enc.iv = key_iv(@passphrase, salt, enc)
      'Salted__' + salt + enc.update(data) + enc.final
    end

    def decrypt(data)
      salt = data[8, 8]
      data = data[16..-1]
      dec = OpenSSL::Cipher.new('AES-256-CBC')
      dec.decrypt
      dec.key, dec.iv = key_iv(@passphrase, salt, dec)
      dec.update(data) + dec.final
    end

    def load
      return unless File.exist?(@filename)
      @passphrase = passphrase unless @passphrase
      f = File.open(@filename, 'rb')
      @secrets = YAML.load(decrypt(f.read))
      f.close
    end

    def save
      unless File.exist?(@filename)
        loop do
          break if (@passphrase = confirm_passphrase(passphrase))
          puts 'passphrase not match'
        end
      end
      f = File.open(@filename, 'wb')
      f.write(encrypt(YAML.dump(@secrets)))
      f.close
    end
  end
end
