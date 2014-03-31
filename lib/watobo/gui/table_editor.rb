# .
# table_editor.rb
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
      class AddTableParmDialog < FXDialogBox
         def location()
            @location_combo.getItemData(@location_combo.currentItem)
         end

         def parmName()
            @parm_name_dt.value
         end

         def parmValue()
            @parm_value_dt.value
         end

         def initialize(owner)
            #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
            super(owner, "Add Parameter", DECOR_ALL)

            @location = nil
            @pname = nil
            @pval = nil

            base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            #  puts "create scopeframe with scope:"
            # @project.scope
            FXLabel.new(frame, "Method:")
            @location_combo = FXComboBox.new(frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            %w( Post Url Cookie ).each do |loc|
               item = @location_combo.appendItem(loc)
               @location_combo.setItemData(item, loc)
            end

            @location_combo.numVisible = 3
            @location_combo.numColumns = 8
            @location_combo.currentItem = 0
            @location_combo.editable = false
            #  @location_combo.connect(SEL_COMMAND, method(:onLocationChanged))

            FXLabel.new(frame, "Parameter:")
            @parm_name_dt = FXDataTarget.new('')
            FXTextField.new(frame, 15,
            :target => @parm_name_dt, :selector => FXDataTarget::ID_VALUE,
            :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            FXLabel.new(frame, "Value:")
            @parm_value_dt = FXDataTarget.new('')
            FXTextField.new(frame, 15,
            :target => @parm_value_dt, :selector => FXDataTarget::ID_VALUE,
            :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            buttons_frame = FXHorizontalFrame.new(base_frame,
            :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

            @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
            @finishButton.enable
            @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
               #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
               self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
            end

            @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
            :target => self, :selector => FXDialogBox::ID_CANCEL,
            :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

         end

      end

      class TableEditor < FXTable
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

         def rawRequest
            parseRequest
         end

         def parseRequest
            cookies = []
            post_parms = []
            url_parms = []
            url = ""

            self.numRows.times do |i|
               case self.getItemText(i, 0)
               when /req/i
                  url = self.getItemText(i, 2)
               when /post/i
                  val = self.getItemText(i, 1)
                  val += "="
                  val += self.getItemText(i, 2).strip
                  post_parms.push(val)
               when /url/i
                  val = self.getItemText(i, 1)
                  val += "="
                  val += self.getItemText(i, 2).strip
                  url_parms.push(val)
               when /cookie2?/i
                  val = self.getItemText(i, 1)
                  val += "="
                  val += self.getItemText(i, 2).strip
                  cookies.push(val)
               end
            end

            @request.setRawQueryParms(url_parms.join("&")) unless url_parms.empty?

            @request.setData(post_parms.join("&")) unless post_parms.empty?

            unless cookies.empty?
               # puts cookies
               @request.removeHeader("Cookie")
               @request.addHeader("Cookie", cookies.join("; "))
            end
            #  puts @request
            @request
         end

         def setRequest(request)
            @request = Watobo::Utils.copyObject(request)
            # now extend the new request with the Watobo mixins
            @request.extend Watobo::Mixin::Parser::Url
            @request.extend Watobo::Mixin::Parser::Web10
            @request.extend Watobo::Mixin::Shaper::Web10

            initTable()
            @request = Watobo::Utils.text2request(request) if request.is_a? String
            # addParmList("REQ", ["URL=#{request.url}"])

            if @request.get_parms.length > 0
               addParmList("URL", @request.get_parms)
            end

            if @request.post_parms.length > 0
               addParmList("Post", @request.post_parms)
            end

            if @request.cookies.length > 0
               addParmList("Cookie", @request.cookies)
            end

         end

         def initialize(owner, opts)
            super(owner, opts)
            @request = nil
            @event_dispatcher_listeners = Hash.new
            initTable()

            self.connect(SEL_COMMAND, method(:onTableClick))

            # KEY_Return
            # KEY_Control_L
            # KEY_Control_R
            # KEY_s
            @ctrl_pressed = false

            addKeyHandler(self)

            self.connect(SEL_DOUBLECLICKED) do |sender, sel, data|
               row = sender.getCurrentRow
               if row >= 0 then
                  self.selectRow(row, false)
                  # open simple editor
               end
            end

            self.connect(SEL_DOUBLECLICKED) do |sender, sel, data|
               row = sender.getCurrentRow
               return nil unless row >= 0 and row < self.numRows
               transcoder = FXTranscoder.new(FXApp.instance, self.getItemText(row, 2))
               transcoder.create
               transcoder.show(Fox::PLACEMENT_SCREEN)
            end

            self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
               unless event.moved?
                  self.cancelInput()
                  ypos = event.click_y
                  row = self.rowAtY(ypos)

                  next unless row >= 0 and row <= self.numRows

                  self.selectRow(row, false) if row < self.numRows
                  FXMenuPane.new(self) do |menu_pane|
                     if row < self.numRows
                        cell_value = self.getItemText(row, 2)
                        cell_value.extend Watobo::Mixin::Transcoders

                        parm_name = self.getItemText(row, 1)

                        FXMenuCaption.new(menu_pane,"- Decoder -")
                        FXMenuSeparator.new(menu_pane)
                        decodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{cell_value.b64decode}")
                        decodeB64.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.b64decode)
                        }
                        decodeHex = FXMenuCommand.new(menu_pane,"Hex(A): #{cell_value.hexdecode}")
                        decodeHex.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.hexdecode)
                        }
                        hex2int = FXMenuCommand.new(menu_pane,"Hex(Int): #{cell_value.hex2int}")
                        hex2int.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.hex2int)
                        }
                        decodeURL = FXMenuCommand.new(menu_pane,"URL: #{cell_value.url_decode}")
                        decodeURL.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.url_decode)
                        }

                        FXMenuSeparator.new(menu_pane)
                        FXMenuCaption.new(menu_pane,"- Encoder -")
                        FXMenuSeparator.new(menu_pane)
                        encodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{cell_value.b64encode}")
                        encodeB64.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.b64encode)
                        }
                        encodeHex = FXMenuCommand.new(menu_pane,"Hex: #{cell_value.hexencode}")
                        encodeHex.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.hexencode)
                        }
                        encodeURL = FXMenuCommand.new(menu_pane,"URL: #{cell_value.url_encode}")
                        encodeURL.connect(SEL_COMMAND) {
                           self.setItemText(row, 2, cell_value.url_encode)
                        }

                        FXMenuSeparator.new(menu_pane)
                        remRow = FXMenuCommand.new(menu_pane,"Remove: #{parm_name}")
                        remRow.connect(SEL_COMMAND) {
                           self.removeRows(row,1, true)
                        }
                        remRow = FXMenuCommand.new(menu_pane,"Add Parameter..")
                        remRow.connect(SEL_COMMAND) { addNewParm() }

                     elsif row >= 0
                        remRow = FXMenuCommand.new(menu_pane,"Add Parameter..")
                        remRow.connect(SEL_COMMAND) { addNewParm() }
                     end
                     menu_pane.create
                     menu_pane.popup(nil, event.root_x, event.root_y)
                     app.runModalWhileShown(menu_pane)
                  end

               end

            end

            self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
               self.fitColumnsToContents(index)
            end
         end

         private

         def addNewParm()

            dlg = AddTableParmDialog.new(self)
            if dlg.execute != 0 then
               loc = dlg.location
               pname = dlg.parmName
               pval = dlg.parmValue
               addParmList(loc, ["#{pname}=#{pval}"])
            end
         end

         def onTableClick(sender, sel, item)
            begin
               row = item.row
               self.selectRow(row, false)
               self.startInput(row,2)
            rescue => bang
               puts bang
            end
         end

         def addKeyHandler(item)
            item.connect(SEL_KEYPRESS) do |sender, sel, event|
               cr = self.currentRow
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
                  # special handling of KEY_Return, because we don't want a linebreak in textbox.
                  if event.code == KEY_Return
                     self.acceptInput(true)
                     notify(:hotkey_ctrl_enter)
                     true
                  else
                     notify(:hotkey_ctrl_f) if event.code == KEY_f
                     notify(:hotkey_ctrl_s) if event.code == KEY_s

                     if event.code == KEY_u
                        text = self.getItemText(cr, 2)
                        #puts "* Encode URL: #{text}"
                        cgi = CGI::escape(text)
                        self.acceptInput(true)
                        self.setItemText(cr, 2, cgi.strip, true)
                     end

                     if event.code == KEY_b
                        text = self.getItemText(cr, 2)
                        puts "* Encode B64: #{text}"
                        b64 = Base64.encode64(text)
                        self.acceptInput(true)
                        self.setItemText(cr, 2, b64.strip, true)
                        puts b64.class
                     end

                     puts "CTRL-SHIFT-U" if event.code == KEY_U
                     if event.code == KEY_U

                        text = self.getItemText(cr, 2)
                        puts "* Encode URL: #{text}"
                        uncgi = CGI::unescape(text)
                        self.acceptInput(true)
                        self.setItemText(cr, 2, uncgi.strip, true)
                     end
                     if event.code == KEY_B
                        text = self.getItemText(cr, 2)
                        puts "* Encode B64: #{text}"
                        b64 = Base64.decode64(text)
                        self.acceptInput(true)
                        self.setItemText(cr, 2, b64.strip, true)
                        puts b64.class
                     end

                     false
                  end
               elsif event.code == KEY_Return
                  self.selectRow(cr)
                  startInput(cr,2)
                  true
               else
                  #puts "%04x" % event.code
                  false
               end
            end

            item.connect(SEL_KEYRELEASE) do |sender, sel, event|
               @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
               false
            end
         end

         def addParmList(parm_origin, parm_list)
            parm_list.each do |parm|
               p,v = parm.split("=")
               lastRowIndex = self.getNumRows
               self.appendRows(1)
               self.setItemText(lastRowIndex, 0, parm_origin)
               self.setItemText(lastRowIndex, 1, p)
               self.setItemText(lastRowIndex, 2, v)
               #   self.fitColumnsToContents(2)
               #          item = getItem(lastRowIndex, 2)

               3.times do |i|
                  self.getItem(lastRowIndex, i).justify = FXTableItem::LEFT
               end
            end

         end

         def initTable
            self.clearItems()
            self.setTableSize(0, 3)

            self.setColumnText( 0, "Location" )
            self.setColumnText( 1, "Parm" )
            self.setColumnText( 2, "Value" )
            #self.setColumnText( 3, "Pinned" )
            #self.setColumnText( 4, "Ignore" )

            self.rowHeader.width = 0
            self.setColumnWidth(0, 60)

            self.setColumnWidth(1, 80)
            self.setColumnWidth(2, 120)
            #self.setColumnWidth(3, 60)
            #self.setColumnWidth(4, 60)
         end
      end
   end
end

if __FILE__ == $0
   # TODO Generated stub
end
