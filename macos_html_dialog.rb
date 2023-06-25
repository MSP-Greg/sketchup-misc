# frozen_string_literal: true

=begin

Run the three below commands in the console after loading this file:

MacOsHtmlDialog.show
MacOsHtmlDialog.close
MacOsHtmlDialog.show

On Windows, everything works as expected.  On macOS, the 2nd show call
opens the HtmlDialog, but the complete html document is rendered with a blank area
at the top of the HtmlDialog 'client' space.

Note that if one places the mouse cursor in the blank area, one cannot open 'DevTools' .
Also, if one opens 'DevTools' from the red area, the html element does not contain
the blank area.

=end

module MacOsHtmlDialog

  class << self
    def show
      @html ||= <<~DOC
        <!DOCTYPE html>
        <html lang='en-US'>
          <head>
            <meta charset='utf-8' />
            <title>macOS Issue on 'reshow'</title>
            <style type='text/css'>
              body {border:0px none; margin:0px; overflow:hidden; background-color:#f04040;
                font-family:Arial, Helvetica, sans-serif;font-size:20px;text-align:center}
              div {color:white;padding-top:5rem;}
            </style>
          </head>
          <body>
            <div>Is there white space above?</div>
          </body>
        </html>
      DOC

      @dlg ||= UI::HtmlDialog.new(
        width: 600,
        height: 300,
        dialog_title: "macOS Issue on 'reshow'",
        scrollable: false,
        resizable: false,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @dlg.set_html @html
      @dlg.center
      # @dlg.set_size 600, 300
      puts "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
      @dlg.show
      @dlg.bring_to_front
      puts "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
    end
    
    def close
      @dlg.close
    end

    def clear
      @dlg = nil
    end
  end
end