# .
# gui_utils.rb
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
    module Utils
      
      def removeTags(text)
        if text.class.to_s =~ /Array/i then
          dummy = []
          text.each do |line|
            chunk = line.gsub(/<[^>]*>/,'').strip
            dummy.push chunk.gsub("\x00","") if chunk.length > 0
          end
          return dummy.join("\n")
        elsif text.class.to_s =~ /String/i then
          chunk = text.gsub(/<[^<]*>/,'').strip
          return chunk.gsub("\x00","")
          #return text.gsub(/\r/,"")
        end
      end

      def cleanupHTTP(text)

        if text.class.to_s =~ /Array/ni then
          dummy = []
          text.each do |line|
            chunk = Watobo::Utils.decode(line).gsub(/\r/,'').strip
            dummy.push chunk.gsub("\x00","")
          end
          return dummy.join("\n")
        elsif text.class.to_s =~ /String/i then
          chunk = Watobo::Utils.decode(text).gsub(/\r/,'').strip
          return chunk.gsub("\x00","")
          #return text.gsub(/\r/,"")

        end
        return nil
      end

      def replace_text(text_box, string)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        text_box.removeText(pos,len)
        text_box.insertText(pos, string)
        text_box.setSelection(pos, string.length, true)
      end

      def addStringInfo(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string = text_box.extractText(pos, len)
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Info -")
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"Length: #{string.length}")

      end

      def addDecoder(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string2decode = text_box.extractText(pos, len)
        string2decode.extend Watobo::Mixin::Transcoders
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Decoder -")
        FXMenuSeparator.new(menu_pane)
        decodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{string2decode.b64decode}")
        decodeB64.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.b64decode)
        }
        decodeHex = FXMenuCommand.new(menu_pane,"Hex(A): #{string2decode.hexdecode}")
        decodeHex.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.hexdecode)
        }
        hex2int = FXMenuCommand.new(menu_pane,"Hex(Int): #{string2decode.hex2int}")
        hex2int.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.hex2int)
        }
        decodeURL = FXMenuCommand.new(menu_pane,"URL: #{string2decode.url_decode}")
        decodeURL.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.url_decode)
        }

      end

      def addEncoder(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string2encode = text_box.extractText(pos, len)
        string2encode.extend Watobo::Mixin::Transcoders
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Encoder -")
        FXMenuSeparator.new(menu_pane)
        encodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{string2encode.b64encode}")
        encodeB64.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.b64encode)
        }
        encodeHex = FXMenuCommand.new(menu_pane,"Hex: #{string2encode.hexencode}")
        encodeHex.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.hexencode)
        }
        encodeURL = FXMenuCommand.new(menu_pane,"URL: #{string2encode.url_encode}")
        encodeURL.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.url_encode)
        }

      end
    end
  end
end
