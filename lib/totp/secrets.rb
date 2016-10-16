require 'yaml'
require 'io/console'
require 'openssl'
require 'curses'
require 'rotp'

module Totp
  # handle encrypted secrets store
  class Secrets
    include Curses
    def initialize(filename)
      @filename = filename
      @secrets = []
      @totp = {}
      @encryption = nil
      @passphrase = passphrase
      if File.exist?(filename)
        load
        init_totp
      end
    end

    def add(entry)
      list
      return if dup?(entry)
      @secrets.reject! { |secret| secret[:id] == entry[:id] }
      @secrets.push(entry)
      save
    end

    def list
      p @secrets
      @secrets.each do |secret|
        puts secret[:id]
      end
    end

    def print
      init_screen
      Curses.timeout = 1000
      begin
        loop do
          count = 30 - Time.now.to_i % 30
          crmode
          show_message(lines - 1, cols - 20, 'Hit any key to quit')
          show_message(0, 0, 'remaining ' + sprintf('%02d', count))
          @secrets.each_index do |index|
            show_message(index + 2, 0, @secrets[index][:id].to_s)
            addstr(' : ' + @totp[@secrets[index][:id]].now.to_s)
          end
          refresh
          break if getch
          refresh
        end
      ensure
        close_screen
      end
    end

    private

    def show_message(x, y, message)
      setpos(x, y)
      addstr(message)
    end

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
