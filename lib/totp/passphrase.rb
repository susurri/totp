module Totp
  # methods to ask passphrase
  module Passphrase
    def ask_noecho(prompt)
      STDOUT.print prompt
      input = STDIN.noecho(&:gets).chomp
      puts
      input
    end

    def passphrase
      ask_noecho('Passphrase: ')
    end

    def confirm_passphrase(pass)
      return pass if pass == ask_noecho('Passphrase(confirm): ')
      nil
    end
  end
end
