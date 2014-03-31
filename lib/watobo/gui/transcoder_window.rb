# .
# transcoder_window.rb
# 
# Copyright 2012 by siberas, http://www.siberas.de
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
module Watobo
   module Gui


      class TranscoderWindow < FXDialogBox

         include Watobo::Gui
         include Watobo::Gui::Utils
         include Watobo::Gui::Icons

         def setText(raw_text)
            @text = raw_text
            @hexViewer.setText(raw_text)
            text = raw_text.gsub(/[^[:print:]]/,'.')
            @textbox.setText(text)
            update_length_info
         end



         def update_length_info
            @len.text = @textbox.to_s.length.to_s
         end



         def onTextChanged(sender, sel, item)
            @text = @textbox.to_s
            @hexViewer.setText(@text)
            update_length_info
         end



         def onHashMD5(sender, sel, item)
            text = @textbox.text
            setText(Digest::MD5.hexdigest(text))
            update_length_info
         end



         def onHashSHA1(sender, sel, item)
            text = @textbox.text
            setText(Digest::SHA1.hexdigest(text))
         end

         def onDecodeB64(sender, sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.b64decode)
         end

         def onEncodeB64(sender, sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.b64encode)
         end

         def onEncodeURL(sender, sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.url_encode)
         end

         def onDecodeURL(sender,sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.url_decode)
         end

         def onDecodeHex(sender, sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.hexdecode)
         end

         def onEncodeHex(sender, sel, item)
            string2encode = @textbox.text
            string2encode.extend Watobo::Mixin::Transcoders
            setText(string2encode.hexencode)
         end

         def initialize(owner, text2transcode)
            # Invoke base class initialize function first
            super(owner, "Transcoder", :opts => DECOR_ALL,:width=>800, :height=>600)
            self.icon = ICON_TRANSCODER
            @text = text2transcode

            main = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)
            info_frame = FXHorizontalFrame.new(main, :opts => FRAME_LINE|LAYOUT_FILL_X)
            main = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            @tabBook = FXTabBook.new(main, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            @lastTabIndex = 0
            textviewer_tab = FXTabItem.new(@tabBook, "Text", nil)
            frame = FXVerticalFrame.new(@tabBook, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            text_frame = FXVerticalFrame.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)

            #btn_frame = FXHorizontalFrame.new(main, :opts => FRAME_LINE|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
            #                                  :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
            btn_frame = FXHorizontalFrame.new(main, :opts => FRAME_SUNKEN|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)

            FXLabel.new(info_frame, "Length:" )
            @len = FXLabel.new(info_frame, "0" )

            hex_tab = FXTabItem.new(@tabBook, "Hex", nil )

            frame = FXVerticalFrame.new(@tabBook, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

            @hexViewer = HexViewer.new(frame)

            @tabBook.connect(SEL_COMMAND) {
               case @tabBook.current
               when 0
                  #
               when 1
                  @hexViewer.setText(@text)
               end
               @lastTabIndex = @tabBook.current

            }

            base64Group = FXGroupBox.new(btn_frame, "Base64", LAYOUT_SIDE_TOP|FRAME_GROOVE, 0, 0, 0, 0)
            btn_decode_b64 = FXButton.new(base64Group, "Encode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onEncodeB64))
            btn_decode_b64 = FXButton.new(base64Group, "Decode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onDecodeB64))


            urlGroup = FXGroupBox.new(btn_frame, "URL", LAYOUT_SIDE_TOP|FRAME_GROOVE, 0, 0, 0, 0)
            btn_decode_b64 = FXButton.new(urlGroup, "Encode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onEncodeURL))
            btn_decode_b64 = FXButton.new(urlGroup, "Decode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onDecodeURL))

            hexGroup = FXGroupBox.new(btn_frame, "Hex", LAYOUT_SIDE_TOP|FRAME_GROOVE, 0, 0, 0, 0)
            btn_decode_b64 = FXButton.new(hexGroup, "Encode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onEncodeHex))
            btn_decode_b64 = FXButton.new(hexGroup, "Decode", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            btn_decode_b64.connect(SEL_COMMAND, method(:onDecodeHex))

            hashGroup = FXGroupBox.new(btn_frame, "Hash", LAYOUT_SIDE_TOP|FRAME_GROOVE, 0, 0, 0, 0)
            btn_hash_md5 = FXButton.new(hashGroup, "MD5", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT|LAYOUT_FILL_X)
            btn_hash_md5.connect(SEL_COMMAND, method(:onHashMD5))
            btn_hash_sha1 = FXButton.new(hashGroup, "SHA-1", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT|LAYOUT_FILL_X)
            btn_hash_sha1.connect(SEL_COMMAND, method(:onHashSHA1))

            # @req_builder = FXText.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @textbox = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
            #@textbox.textStyle |= TEXT_FIXEDWRAP

            @textbox.connect(SEL_CHANGED, method(:onTextChanged))

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
                     target = FXMenuCheck.new(menu_pane, "word wrap" )
                     target.check = ( @textbox.textStyle & TEXT_WORDWRAP > 0 ) ? true : false

                     target.connect(SEL_COMMAND) do |tsender, tsel, titem|
                        if tsender.checked?
                           @textbox.textStyle |= TEXT_WORDWRAP
                        else
                           @textbox.textStyle ^= TEXT_WORDWRAP
                        end
                     end
                     menu_pane.create
                     menu_pane.popup(nil, event.root_x, event.root_y)
                     app.runModalWhileShown(menu_pane)
                  end
               end
            end

            if text2transcode then
               @init_text = text2transcode
               @textbox.setText(@init_text)
               update_length_info()
            end
         end

      end

   end
end
