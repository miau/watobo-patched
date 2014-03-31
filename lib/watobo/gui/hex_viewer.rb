# .
# hex_viewer.rb
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
    class HexViewer < FXHorizontalFrame
      def normalizeText(text)
        dummy = []
        begin
          text.headers.each do |h|
            dummy.push h.strip.unpack("C*").pack("C*") + "\r\n"
          end
          dummy.push "\r\n"
          dummy.push text.body.unpack("C*").pack("C*")
          dummy = dummy.join
        rescue => bang
          dummy = text
        end
        return dummy
      end
      
      def setText(tobject)
        raw_text = tobject
        
        if tobject.respond_to? :has_body?
          raw_text = ""
         raw_text << tobject.body.to_s unless tobject.body.nil? 
        end
            
       
        
        initTable()
        
        if raw_text and not raw_text.empty? then
          raw_text = normalizeText(raw_text)
          pos = 1
          col = 0
          
          row = @hexTable.getNumRows
          
          @hexTable.appendRows(1)
          @hexTable.rowHeader.setItemJustify(row, FXTableItem::LEFT)    
          @hexTable.setRowText(row, "%0.4X" % row.to_s)
          
          while pos <= raw_text.length
            chunk = raw_text[pos-1].unpack("H2")[0]
            @hexTable.setItemText(row, col, chunk)
            @hexTable.getItem(row, col).justify = FXTableItem::LEFT
            
            if pos % 16 == 0 then
              chunk = raw_text[row*16..pos-1]
              
             # puts chunk
              @hexTable.setItemText(row, 16, chunk.gsub(/[^[:print:]]/,'.')) if !chunk.nil?
              @hexTable.getItem(row, 16).justify = FXTableItem::LEFT
              
              row = @hexTable.getNumRows
              @hexTable.appendRows(1)
              
              # puts "=#{pos}/#{row}"
              @hexTable.rowHeader.setItemJustify(row, FXTableItem::LEFT)        
              @hexTable.setRowText(row, "%0.4X" % row.to_s)
              
              col = -1
            end
            pos += 1
            col += 1 
          end
          chunk = raw_text[row*16..pos-1]
          @hexTable.setItemText(row, 16, chunk.gsub(/[^[:print:]]/,'.')) if !chunk.nil?
              @hexTable.getItem(row, 16).justify = FXTableItem::LEFT
          
        end
      end
      
      def initialize(owner)
        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        sunken = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @hexTable = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        
        
      end
      
      private
      def initTable
        @hexTable.clearItems()
        @hexTable.setTableSize(0, 17)
        @hexTable.rowHeader.width = 50
        0.upto(15) do |i|       
          htext = "%X" % i
          @hexTable.setColumnText( i, htext)          
          @hexTable.setColumnWidth(i, 35)
        end  
        @hexTable.setColumnWidth(16, 115)
      end
    end
  end
end
