require 'curses'

module Totp
  # curses window to show codes
  class Window
    include Curses
    def init_curses
      init_screen
      Curses.timeout = 1000
      crmode
    end

    def show_curses(secrets, totp)
      show_header_footer
      ypos = 2
      secrets.each do |secret|
        show_message(ypos, 0, secret[:id] + ' : ' +
                     totp[secret[:id]].now)
        ypos += 1
      end
      refresh
    end

    def show_header_footer
      show_message(lines - 1, cols - 20, 'Hit any key to quit')
      show_remaining
    end

    def show_message(x, y, message)
      setpos(x, y)
      addstr(message)
    end

    def show_remaining
      count = 30 - Time.now.to_i % 30
      show_message(0, 0, 'remaining ' + format('%02d', count))
    end

    def getch
      Curses.getch
    end

    def close
      close_screen
    end
  end
end
