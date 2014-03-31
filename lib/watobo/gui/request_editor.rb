# .
# request_editor.rb
# 
# Copyright 2013 by siberas, http://www.siberas.de
# 
# This file is part of WATOBO (Web Application Tool Box)
#        http://watobo.sourceforge.com
# 
# WATOBO is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 2 of the License.
# 
# WATOBO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with WATOBO; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# .
# @private 
module Watobo#:nodoc: all
  module Gui
    class SimpleTextView < FXVerticalFrame

      attr_accessor :textbox
      attr_accessor :style
      attr_accessor :max_len

      include Watobo::Constants
      include Watobo::Gui::Utils

      public
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def resetMatches()
        @pattern_matches.clear
      end

      def rawRequest()
        @textbox.text
      end

      def numMatches()
        @pattern_matches.length
      end

      def textStyle=(style)
        @textbox.textStyle = style
      end

      def textStyle()
        @textbox.textStyle
      end

      def setFont(font_type=nil, size=nil)
        new_size = size.nil? ? GUI_REGULAR_FONT_SIZE : size
        new_font_type = font_type.nil? ? "helvetica" : font_type
        new_font = FXFont.new(getApp(), new_font_type, new_size)
        new_font.create
        @textbox.font = new_font
      end

      def initialize(owner, opts)

        @logger = (defined? owner.logger) ? owner.logger : nil
        @pattern_matches = []
        @text = ""

        @event_dispatcher_listeners = Hash.new

        super(owner, opts)
        # Construct some hilite styles
        @style = 1 # default style
        @max_len = 0

        @small_font = FXFont.new(getApp(), "helvetica", GUI_SMALL_FONT_SIZE)
        @small_font.create

        @big_font = FXFont.new(getApp(), "helvetica", GUI_REGULAR_FONT_SIZE)
        @big_font.create

        @last_button_pressed = SEL_TYPE_HIGHLIGHT

        # Construct some hilite styles
        hs_green = FXHiliteStyle.new
        hs_green.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_green.normalBackColor = FXRGBA(0,255,0,1)   # FXColor::White
        hs_green.style = FXText::STYLE_BOLD

        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
        hs_red.style = FXText::STYLE_BOLD

        # @req_builder = FXText.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
      
        @textbox = FXText.new(self,  :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @textbox.extend Watobo::Mixins::RequestParser
  
        # Enable the style buffer for this text widget
        @textbox.styled = true
        # Set the styles
        @textbox.hiliteStyles = [ hs_green, hs_red]

        @textbox.editable = false

        @textbox.textStyle |= TEXT_WORDWRAP

        @textbox.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|

          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|

              pos = @textbox.selStartPos
              len = @textbox.selEndPos - pos

              selection = @textbox.extractText(pos, len)
              addStringInfo(menu_pane, sender)
              addDecoder(menu_pane, sender)
              addEncoder(menu_pane, sender) if @textbox.editable?

              FXMenuSeparator.new(menu_pane)
              FXMenuCaption.new(menu_pane,"- Copy -")
              FXMenuSeparator.new(menu_pane)
              copyText = FXMenuCommand.new(menu_pane,"copy text: #{selection}", nil, @textbox, FXText::ID_COPY_SEL)

              FXMenuSeparator.new(menu_pane)
              FXMenuCaption.new(menu_pane,"- Transcoder -")
              FXMenuSeparator.new(menu_pane)
              send2transcoder = FXMenuCommand.new(menu_pane,"send to transcoder")
              send2transcoder.connect(SEL_COMMAND) {
                t = TranscoderWindow.new(FXApp.instance, selection)
                t.create
                t.show(Fox::PLACEMENT_SCREEN)
              }
              FXMenuSeparator.new(menu_pane)
              target = FXMenuCheck.new(menu_pane, "word wrap" )
              target.check = ( @textbox.textStyle & TEXT_WORDWRAP > 0 ) ? true : false
              target.connect(SEL_COMMAND) { @textbox.textStyle ^= TEXT_WORDWRAP }

              target = FXMenuCheck.new(menu_pane, "big font" )
              target.check = ( @textbox.font == @small_font ) ? false : true
              target.connect(SEL_COMMAND) { |ts, tsel, titem|
                if ts.checked?
                @textbox.font = @big_font
                else
                @textbox.font = @small_font
                end

              }

              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)

            end
          end
        end
      end

      def editable=(e)
        @textbox.editable = e
      end

      def editable?()
        @textbox.editable?
      end

      def setText(text, prefs={})
        @text = normalizeText(text)
      
        showText(@text)
        true
      end
      
      alias_method :setRequest, :setText

      def filter(pattern)
        #dummy = @textbox.to_s.split(/\n/)
        dummy = @text.split(/\n/)
        @textbox.setText('')
        filtered = []
        dummy.each do |line|
          begin
            if line =~ /#{pattern}/i then
            filtered.push line
            end
          rescue => bang
          puts
          puts bang
          pattern = Regexp.quote(pattern)
          retry
          end
        end
        showText(filtered.join("\n"))
      end

      def highlight(pattern)
        sindex = nil
        eindex = nil

        dummy = @textbox.to_s
        #remove previous highlighting
        @textbox.setText(dummy)

        matchPattern(pattern)

        # puts "* found pattern #{pattern} #{@pattern_matches.length} times"
        @pattern_matches.each do |start, len|
          begin
            @textbox.changeStyle(start, len, @style)
          rescue => bang
          puts "outch"
          puts bang
          end
        end

        return @pattern_matches.length
      end

      def makeMatchVisible(match_index=0)
        return true if @pattern_matches.empty?
        return false if match_index > ( @pattern_matches.length - 1 )
        if @pattern_matches[match_index] then
        pos = @pattern_matches[match_index][0]
        len =@pattern_matches[match_index][1]

        @textbox.setCenterLine(pos)

        #   @textbox.makePositionVisible(pos + len)
        @textbox.makePositionVisible(@textbox.lineEnd(pos))
        @textbox.makePositionVisible(pos)

        @textbox.setCursorPos(pos)
        end
        return true
      end

      private

      # returns an array of matches. each match consists of two values [start, len]
      def matchPattern(pattern)
        sindex = nil
        eindex = nil

        pos = 0
        @pattern_matches.clear

        loop do
          sindex, eindex = @textbox.findText(pattern, pos, SEARCH_EXACT|SEARCH_IGNORECASE|SEARCH_FORWARD)

          sindex, eindex = @textbox.findText(pattern, pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex

          sindex, eindex = @textbox.findText(Regexp.quote(pattern),pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex

          break if not sindex or sindex.length == 0

          pos = eindex.last+1
          sindex.length.times do |i|
            start = sindex[i]
            len = eindex[i] - sindex[i]
            @pattern_matches.push [ start, len] if start >= 0
          end

          break if sindex.last < 0

        end

        return @pattern_matches
      end

      def showText(text)
        begin
        if @max_len > 0 and @max_len < text.length
        text = text[0..@max_len] + "\n---8<--- WATOBO ---8<---\n* PRESS RESET TO SEE FULL RESPONSE *"
        end
       # text.encode('iso_8859_1')
       # UTF-8 CleanUp
       text = text.unpack("C*").pack("C*")
        text.gsub!(/\x0d/u, '')
       text.gsub!(/[\x00-\x09\x0b-\x1f\x7f-\xff]+/m,'.')
           @textbox.setText(text)
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          @textbox.setText(text)
        end
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def normalizeText(text)
        begin
        t = text
        return "" if text.nil?
        t = text.join if text.is_a? Array
        t = t.unpack("C*").pack("C*")
        
 t.gsub!(/\x0d/, '')
       t.gsub!(/[\x00-\x09\x0b-\x1f\x7f-\xff]+/m,'.')
        return t
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        text.join
      end

      def log(text,e=nil)
        #   @logger.addError "Not a valid expression! \n#{e}"
        t = Time.now
        now = t.strftime("%m/%d/%Y @ %H:%M:%S")
        msg = "[#{now}] #{text}"
        notify(:error, msg)
        puts msg
        if e then
        puts e
        puts e.backtrace
        end
      end

    end

    class RequestEditor < SimpleTextView
      def initialize(owner, opts)
        super(owner, opts)

        @textbox.textStyle -= TEXT_WORDWRAP

        @textbox.editable = true
        @markers = []

        @textbox.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|
              addStringInfo(menu_pane, sender)
              addDecoder(menu_pane, sender)
              addEncoder(menu_pane, sender)
              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)
            end

          end
        end

        @textbox.connect(SEL_REPLACED, method(:onTextChanged))
        @textbox.connect(SEL_DELETED, method(:onTextChanged))

        # KEY_Return
        # KEY_Control_L
        # KEY_Control_R
        # KEY_s
        @ctrl_pressed = false

        @textbox.connect(SEL_KEYPRESS) do |sender, sel, event|
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_F1
            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "<ctrl-enter> - Send Request",
                  "<ctrl-b> - Encode Base64",
                  "<ctrl-shift-b> - Decode Base64",
                  "<ctrl-u> - Encode URL",
                  "<ctrl-shift-u> - Decode URL"
                ].each do |hk|
                  FXMenuCaption.new(menu_pane, hk)
                end

                menu_pane.create

                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end
          end
          if @ctrl_pressed
            if event.code == KEY_Return
            notify(:hotkey_ctrl_enter)
            true # special handling of KEY_Return, because we don't want a linebreak in textbox.
            else
              notify(:hotkey_ctrl_f) if event.code == KEY_f
              notify(:hotkey_ctrl_s) if event.code == KEY_s
              pos = @textbox.selStartPos
              len = @textbox.selEndPos - pos
              unless len==0
                text = @textbox.extractText(pos,len)
                rptxt = case event.code
                when KEY_u
                  CGI::escape(text)
                when KEY_b
                  Base64.strict_encode64(text)
                when KEY_U
                  CGI::unescape(text)
                when KEY_B
                  Base64.decode64(text)
                else
                text
                end
              @textbox.replaceText(pos,len,rptxt)
              @textbox.setSelection(pos,rptxt.length)
              end
            false
            end
          else
          #puts "%04x" % event.code
          false
          end
        end

        @textbox.connect(SEL_KEYRELEASE) do |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        end

      end

      def parseRequest
        begin
          return @textbox.to_request
        rescue SyntaxError, LocalJumpError, NameError => bang
          puts bang
          puts bang.backtrace
        #  puts bang.backtrace if $DEBUG
          notify(:error, "#{$!}")
        rescue => bang
        puts bang
        notify(:error, "Could not parse request: #{$!}")
        end

        return nil
      end
      

      private

      def onTextChanged(sender, sel, changed)
        begin
          dummy = changed.ins
          dummy += changed.del

          pos = changed.pos

          pattern = "(%%.*?%%)"
          #if dummy =~ /%/ then

          @markers = highlight(pattern)
          @textbox.setCursorPos(pos)
          # else
          #   @markers.each do |start, len|
          #     if pos >= start and pos <= start + len then
          #       @markers = highlight(pattern)
          #       @textbox.setCursorPos(pos)
          #       break
          #     end
          #   end
          # end

        rescue => bang
        puts "!!!ERROR: onTextChanged"
        puts bang
        end
      end
    end

  # -> # module Watobo::Gui
  end
end
