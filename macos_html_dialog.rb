# frozen_string_literal: true

=begin
load file, runs itself

code creates an HtmlDialog, shows it, closes it, then shows it again
several dimensional metric are compared, if they're not equal, info is output
to console

windows passes (outputs 'passed' to console)

macOS fails with window.innerHeight decreasing when the HtmlDialog is shown
the 2nd time, it also shows a blank space above the html element.
=end

require 'json'

module MacOsHtmlDialog
  TIMER_INTERVAL = 0.3

  class << self
    def run
      @html ||= <<~DOC
        <!DOCTYPE html>
        <html lang='en-US'>
          <head>
            <meta charset='utf-8' />
            <title>macOS Issue on 'reshow'</title>
            <style type='text/css'>
              body {border:0px none; margin:0px; overflow:hidden; background-color:#f04040;
                font-family:Arial, Helvetica, sans-serif;font-size:20px;text-align:center;
                width:100%; height:100%;
              }
              div {color:white;padding-top:5rem;}
            </style>
            <script>
              const winLoad = () => {
                const el = document.getElementsByTagName('html').item(0)
                const rect = el.getBoundingClientRect()

                const win = {
                  screenLeft:  window.screenLeft,
                  screenTop:   window.screenTop,
                  innerWidth:  window.innerWidth,
                  innerHeight: window.innerHeight,
                  outerWidth:  window.outerWidth,
                  outerHeight: window.outerHeight,
                }
                const screen = {
                  availLeft: window.screen.availLeft,
                  availTop:  window.screen.availTop
                }
                info = {
                  html_bcrect: rect,
                  window: win,
                  screen: screen
                }
                sketchup.info(JSON.stringify(info))
              }
              document.addEventListener('DOMContentLoaded', winLoad)
            </script>
          </head>
          <body>
            <div>Is there white space above?</div>
          </body>
        </html>
      DOC

      @state = 0
      @data = []
      @dlg  = nil

      @aacb = -> (_, ret) { @data << JSON.parse(ret, symbolize_names: true) }

      show
      UI.start_timer(TIMER_INTERVAL) { @dlg.close }
      UI.start_timer(TIMER_INTERVAL * 2) { show }
      UI.start_timer(TIMER_INTERVAL * 3) do
        failed = false
        show_first = @data[0]
        show_last =  @data[1]

        %i[html_bcrect window screen].each do |type|
          first = show_first[type]
          last  = show_last[type]

          first.each do |k, v|
            unless v == last[k]
              puts "failed #{type} #{k}  1st show #{first[k]} != #{last[k]} 2nd show\n"
              failed = true
            end
          end
        end

        puts "passed\n" unless failed

        @dlg.close
        @dlg = nil
        @html = nil
      end
    end

    def show
      @dlg ||= UI::HtmlDialog.new(
        width: 600,
        height: 300,
        dialog_title: 'macOS Issue on 2nd show',
        scrollable: false,
        resizable: false,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @dlg.add_action_callback 'info', &@aacb

      @dlg.set_html @html
      @dlg.center
      @dlg.show
    end

    def clear
      @dlg = nil
      @html = nil
    end
  end
end
MacOsHtmlDialog.run
