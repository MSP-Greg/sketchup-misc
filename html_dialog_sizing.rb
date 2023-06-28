# frozen_string_literal: true

=begin

This file shows three bugs with new SU versions.  They affect
UI::HtmlDialog sizing & resizing, centering, and 'show' after 'close'.

1. set_size & center before show
2. show, close, show again
3. set_size after show

Load this file from the Ruby console.  The below describes what I seen on my monitor,
other monitors may show it differently.

                     Win SU 2022    Win SU new     macOS SU new
load file (show)
  sized                correct      too small        correct
  load centered          yes           no              yes

HtmlDialogSizing.close
HtmlDialogSizing.show

  shown centered         yes        not visible        yes

HtmlDialogSizing.larger

  shown larger           yes        not visible      no change


Note that if the Windows SU dimension/size values are scaled by
UI.scale_factor (same as js DOM window.devicePixelRatio), the
HtmlDialog is correctly sized.

Windows with new SU is quite messed up. MacOS is better, but resizing a visible
HtmlDialog doesn't work, with get_size shows the dimensions used in set_size?

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
            <div>123456789 123456789 0123456789 0123456789</div>
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
      puts "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
      @dlg.set size(550, 180) if @shown
      @dlg.center
      @dlg.show
      @dlg.bring_to_front
      @shown ||= true
      puts "#{@dlg.class}  After show called\n" \
        "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
    end

    def larger
      show unless @dlg&.visible?
      @dlg.set_size 700, 300
      puts "#{@dlg.class}  After set_size called\n" \
        "#{@dlg.class}  visible #{@dlg.visible?}  size #{@dlg.get_size.inspect}"
    end

    def close
      @dlg.close
      nil
    end

    def clear
      @dlg = nil
      @html = nil
      @shown = nil
    end
  end
end
puts 'HtmlDialogSizing.show'
HtmlDialogSizing.show
