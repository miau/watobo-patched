# .
# cipher_table.rb
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
  module Plugin
    module Sslchecker
      module Gui
        
        class CipherTableController < FXHorizontalFrame
          def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
          end

          def clearEvents(event)
            @event_dispatcher_listener[event].clear
          end

          def notify(event, *args)
            if @event_dispatcher_listeners[event]
              @event_dispatcher_listeners[event].each do |m|
                m.call(*args) if m.respond_to? :call
              end
            end
          end

          def initialize(owner, opts)
            super(owner,opts)
            @event_dispatcher_listeners = Hash.new
            @good_cb = FXCheckButton.new(self, "good", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            @good_cb.connect(SEL_COMMAND) { update_table }
            @good_cb.checkState = true
            @bad_cb = FXCheckButton.new(self, "bad", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            @bad_cb.connect(SEL_COMMAND) { update_table }
            @bad_cb.checkState = true
            @na_cb = FXCheckButton.new(self, "n/a", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            @na_cb.connect(SEL_COMMAND) { update_table }
            @na_cb.checkState = true
            FXButton.new(self, "copy").connect(SEL_COMMAND) { notify(:copy_table) }
         #   FXButton.new(self, "clear").connect(SEL_COMMAND) { notify(:clear_ciphers) }

          end

          def update_table
            show_prefs = CipherTable::CTF_NONE
            show_prefs = show_prefs | CipherTable::CTF_BAD if @bad_cb.checked?
            show_prefs = show_prefs | CipherTable::CTF_GOOD if @good_cb.checked?
            show_prefs = show_prefs | CipherTable::CTF_NA if @na_cb.checked?
            notify(:apply_filter, show_prefs)
          end
        end

        class CipherTable < FXTable
          CTF_NONE = 0x00
          CTF_GOOD = 0x01
          CTF_BAD = 0x02
          CTF_NA = 0x04
          CTF_ALL = 0x07

          attr :ciphers
          attr_accessor :min_bit_length
          attr_accessor :filter
          
          # this returns a comma seperated list of the table [string] 
          def to_csv
            csv = ""
           self.each_row do |c,b,r|
              csv << c.text.strip << ";"
              csv << b.text.strip << ";"
              csv << r.text.strip
              csv << "\n"
            end
            csv
          end

          def setNewFont(font_type=nil, size=nil)
            begin
              new_size = size.nil? ? GUI_REGULAR_FONT_SIZE : size
              new_font_type = font_type.nil? ? "helvetica" : font_type
              new_font = FXFont.new(getApp(), new_font_type, new_size)
              new_font.create

              self.font = new_font
              self.rowHeader.font = new_font
              self.defRowHeight = new_size+10

              updateTable()

            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
          end

          def add_cipher( cipher )

            [ :name, :bits, :result ].each do |k|
              return false unless cipher.has_key? k
            end

            @ciphers.push cipher
            add_cipher_row(cipher)

            true
          end

         def show_all
            @filter = CTF_ALL
          end

          def update_table
          #  puts "update table: #{filter}"
            self.clearItems
            initColumns
            @ciphers.each do |c|
              add_cipher_row c
            end
          end

          def clear_ciphers
            self.clearItems
            initColumns
            @ciphers.clear
          end

          def initialize(owner, opts)
            super(owner, :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
            @ciphers = []
            @min_bit_length = 128

            @columns = Hash.new
            @columns[:cipher] = { :label => "Cipher", :pos => 0, :width => 250 }
            @columns[:bits] = { :label => "Bits", :pos => 1, :width => 100 }
            @columns[:result] = { :label => "Result", :pos => 2, :width => 50 }

            @filter = CTF_ALL

            init_icons
            initColumns()
            adjustCellWidth
          end

          private

          def init_icons
            begin
              path = File.expand_path(File.join(File.dirname(__FILE__), "..", "icons" ))
              file = "green_16x16.ico"
              icon_file = File.join(path, file)
              # puts icon_file

              @icon_ok = Watobo::Gui.load_icon(icon_file)

              file = "red_16x16.ico"
              icon_file = File.join(path, file)
              @icon_bad = Watobo::Gui.load_icon(icon_file)

              file = "grey_16x16.ico"
              icon_file = File.join(path, file)
              @icon_na = Watobo::Gui.load_icon(icon_file)
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end

          def initColumns()
            self.setTableSize(0, @columns.length)
            self.visibleRows = 20
            self.visibleColumns = @columns.length

            @columns.each do |key, opts|
              self.setColumnText( opts[:pos], opts[:label] )
            #self.setColumnIcon(@col_order.index(TABLE_COL_SSL), TBL_ICON_LOCK)# puts self.getItem(@col_order.index(col), 0  ).class.to_s
            end
            
            adjustCellWidth

          end

          def adjustCellWidth()
            begin
              self.rowHeader.width = 0
              @columns.each_value do |opts|
                self.setColumnWidth( opts[:pos], opts[:width] )
              end
            rescue => bang
              puts bang
              puts bang.backtrace
              puts "!!!ERROR: adjustCellWidth"
            end

          end

          def add_cipher_row(cipher)
            add_cipher = ( @filter == CTF_ALL ) ? true : false

            if cipher[:result] == false
              # @result_viewer.appendStyledText("checked: #{cipher} - #{bits} - #{result}\n",0)
              text = "N/A"
              icon = @icon_na
              add_cipher = true if ( @filter & CTF_NA > 0 )

            elsif cipher[:bits].to_i < @min_bit_length
              # @result_viewer.appendStyledText("checked: #{cipher} - #{bits} - #{result}\n",2)
              text = "BAD"
              icon = @icon_bad
              add_cipher = true if ( @filter & CTF_BAD > 0 )
            else
              text = "OK"
              icon = @icon_ok
              add_cipher = true if ( @filter & CTF_GOOD > 0 )
            # @result_viewer.appendStyledText("checked: #{cipher} - #{bits} - #{result}\n",1)
            end

            if add_cipher
              lastRowIndex = self.getNumRows
              self.appendRows(1)

              index = @columns[:cipher][:pos]
              self.setItemText(lastRowIndex, index, cipher[:name])
              self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

              index = @columns[:bits][:pos]
              self.setItemText(lastRowIndex, index, cipher[:bits].to_s)
              self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT

              index = @columns[:result][:pos]
              
              
              self.setItemIcon(lastRowIndex, index, icon)
              self.setItemIconPosition(lastRowIndex, index, FXTableItem::BEFORE)
              self.setItemText(lastRowIndex, index, text)
              self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT
            end
          end

        end

      end
    end
  end
end