# frozen_string_literal: true

=begin

Load this file from the Ruby console.

On Window SU 2022, the text 'Is this visible?' is visible.

On Windows and newer SU versions, it is not.

On macOS and newer SU versions, the text is visible.

=end

module HtmlDialogSizing

  class << self
    def show
      @shown = nil
      @html ||= <<~DOC
        <!DOCTYPE html>
        <html lang='en-US'>
          <head>
            <meta charset='utf-8' />
            <title>macOS Issue on 'reshow'</title>
            <style type='text/css'>
              body {border:0px none; margin:0px;
                font-family:Arial, Helvetica, sans-serif;font-size:20px;
                text-align:right;
                overflow:hidden;
                width: 500px;}
              div {padding-top:100px;}
            </style>
          </head>
          <body>
            <div>Is this visible?</div>
          </body>
        </html>
      DOC

      @dlg ||= UI::HtmlDialog.new(
        width: 550,
        height: 180,
        dialog_title: "UI::HtmlDialog sizing issue",
        scrollable: false,
        resizable: false,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @dlg.set_html @html
      @dlg.center

      puts "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
      @dlg.set size(550, 180) if @shown
      @dlg.show
      puts "#{@dlg.class}  After show called"
      @dlg.bring_to_front
      puts "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"

      @shown ||= true
    end
    
    def close
      @dlg.close
    end

    def clear
      @dlg = nil
      @shown = nil
    end
  end
end

HtmlDialogSizing.show