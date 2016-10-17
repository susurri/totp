require 'yaml'
require 'io/console'
require 'openssl'
require 'rotp'
require 'totp/window'
require 'totp/passphrase'

module Totp
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

    def encrypt(data)
      enc = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
      salt = OpenSSL::Random.random_bytes(8)
      enc.encrypt
      digest = OpenSSL::Digest.new('sha512')
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac(@passphrase, salt, 2000,
                                          enc.key_len + enc.iv_len, digest)
      enc.key = key_iv[0, enc.key_len]
      enc.iv = key_iv[enc.key_len, enc.iv_len]
      'Salted__' + salt + enc.update(data) + enc.final
    end

    def decrypt(data)
      salt = data[8, 8]
      data = data[16..-1]
      dec = OpenSSL::Cipher::Cipher.new('AES-256-CBC')
      dec.decrypt
      digest = OpenSSL::Digest.new('sha512')
      key_iv = OpenSSL::PKCS5.pbkdf2_hmac(@passphrase, salt, 2000,
                                          dec.key_len + dec.iv_len, digest)
      dec.key = key_iv[0, dec.key_len]
      dec.iv = key_iv[dec.key_len, dec.iv_len]
      dec.update(data) + dec.final
    end

    def load
      return unless File.exist?(@filename)
      @passphrase = passphrase
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
