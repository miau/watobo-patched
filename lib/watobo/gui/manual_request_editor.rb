# .
# manual_request_editor.rb
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

      class RequestBuilder < FXVerticalFrame

         def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
         end

         def clearEvents(event)
            @event_dispatcher_listener[event].clear
         end

         def setRequest(request)
            begin
               @text_edit.setText(request)
               @parm_table.setRequest(request)

               if request.is_a? Array
                  text = "#{request.first}"
               else
                  text = request.slice(/.* HTTP\/\d\.\d/)
               end
               #text.gsub!(/\?.*/,"")
               #text.gsub!(/ HTTP\/.*/,"")
               @req_line.setText(text.strip)
            rescue => bang
               puts bang
               # puts bang.backtrace if $DEBUG
               # puts request
               # puts "== EOE =="
            end
         end

         def highlight(pattern)
            @text_edit.highlight(pattern)
         end

         def rawRequest
            case @tab.current
            when 0
               @text_edit.rawRequest
            when 1
               @parm_table.rawRequest
            end
         end

         def parseRequest

            case @tab.current
            when 0

               @text_edit.parseRequest
            when 1

               @parm_table.parseRequest
            end
         end

         def initialize(owner, opts)
            super(owner,opts)

            @event_dispatcher_listeners = Hash.new

            @tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

            FXTabItem.new(@tab, "Text", nil)
            frame = FXVerticalFrame.new(@tab, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            @text_edit = Watobo::Gui::RequestEditor.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)

            @text_edit.subscribe(:error) { |msg| notify(:error, msg) }

            FXTabItem.new(@tab, "Table", nil)
            frame = FXVerticalFrame.new(@tab, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @req_line = FXText.new(frame, :opts => LAYOUT_FILL_X|TEXT_FIXEDWRAP)
            @req_line.visibleRows = 1
            @req_line.backColor = @req_line.parent.backColor
            @req_line.disable
            @parm_table = TableEditor.new(frame, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
            # setup message chain
            @parm_table.subscribe(:hotkey_ctrl_enter){ notify(:hotkey_ctrl_enter) }
            @text_edit.subscribe(:hotkey_ctrl_enter){ notify(:hotkey_ctrl_enter) }

         end

         private

         def notify(event, *args)
            if @event_dispatcher_listeners[event]
               @event_dispatcher_listeners[event].each do |m|
                  m.call(*args) if m.respond_to? :call
               end
            end
         end
      end

      class SelectionInfo < FXVerticalFrame
         def update(info)
            begin
               @hid_label.text = info[:hid] || "-"
               @url_label.text = info[:url] || "-"
               @length_label.text = info[:length] || "-"
               @status_label.text = info[:status] || "-"

            rescue => bang
               puts "!!! Could not update SelectionInfo"
               puts bang
            end
         end

         def clear()
            @hid_label.text = "-"
            @url_label.text = "-"
            @length_label.text = "-"
            @status_label.text = "-"
         end

         def initialize(owner, opts)
            super(owner, opts)
            frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
            FXLabel.new(frame, "History-ID: ")
            @hid_label = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
            FXLabel.new(frame, "URL: ")
            @url_label = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
            FXLabel.new(frame, "Length: ")
            @length_label = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
            FXLabel.new(frame, "Status: ")
            @status_label = FXLabel.new(frame, " - ")
         end
      end

      class HistoryItem

         attr :request
         attr :response
         attr :raw_request
         def initialize(request, response, raw_request)
            @request = request
            @response = response
            @raw_request = raw_request
         end
      end

      class HistoryButton < FXVerticalFrame
         attr :item
         def reset()
            self.backColor = @backColor
         end

         def highlight()
            self.backColor = FXColor::Red
         end

         def update(history_item)
            @button.text = history_item.id.to_s
            #@button.text = "Huhule"
            #puts "!update Button #{@button}"
            @button.update()
            @item = history_item
         end

         def initialize(owner, text, target, opts)
            super(owner, opts)
            @item = nil
            @backColor = self.backColor

            @button = FXButton.new(self, text, nil, target, DiffFrame::ID_HISTORY_BUTTON, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

         end
      end

      class HistorySlider < FXScrollWindow
         def update(history)
            @history = history
            reset()
            history.length.times do |i|
               begin

                  @buttons[i].update(history[i])
               rescue => bang
                  puts bang
               end
            end
         end

         def getItem(id)
            item = nil
            @history.each do |h|
               item = h if h.id == id
               break if item
            end
            return item
         end

         def reset()
            @buttons.each do |b|
               b.reset()
            end

         end

         def initialize(owner, target, history_size, opts)
            @size = history_size
            @buttons = []
            @history = []
            super(owner, opts)
            frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X, :padding => 0)
            @size.times do |i|
               @buttons.push HistoryButton.new(frame, 'empty', target, :opts => FRAME_NONE|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 50, :height => 50)
            end
         end
      end

      class DiffFrame < FXVerticalFrame
         include Responder

         ID_HISTORY_BUTTON = FXMainWindow::ID_LAST
         def onHistoryButton(sender, sel, event)
            @history_slider.reset()
            sender.parent.backColor = FXColor::Red
            @slider_selection = sender.parent.item
         end

         def updateHistory(history)
            @slider_selection = nil
            @history = history
            # @history_slider.update(history)
            updateHistoryTable()
            # updateSelections()
         end

         def onTableClick(sender,sel,item)
            begin

               row = item.row
               @historyTable.selectRow(row, false)
               hi = @historyTable.getRowText(row).to_i - 1

               if @first_selection and @second_selection
                  @first_selection = nil
                  @second_selection = nil
               end

               if !@first_selection
                  @first_selection = @history[hi]
               else
                  @second_selection = @history[hi]
               end

               updateSelection()

            rescue => bang
               puts "!!!ERROR: onTableClick"
               puts bang
               puts "!!!"

            end
         end

         def initHistoryTable()
            @historyTable.clearItems()
            @historyTable.setTableSize(0, 3)

            @historyTable.setColumnText( 0, "STATUS" )
            @historyTable.setColumnText( 1, "LENGTH" )
            @historyTable.setColumnText( 2, "URL" )

            @historyTable.rowHeader.width = 50
            @historyTable.setColumnWidth(0, 100)

            @historyTable.setColumnWidth(1, 100)
            @historyTable.setColumnWidth(2, 200)

         end

         def updateHistoryTable()
            begin
               @historyTable.clearItems()
               initHistoryTable()

               @history.each do |h|
                  lastRowIndex = @historyTable.getNumRows
                  @historyTable.appendRows(1)
                  @historyTable.setRowText(lastRowIndex, (@history.index(h) + 1 ).to_s)
                  @historyTable.setItemText(lastRowIndex, 0, h.response.status) if h.response.respond_to? :status
                  @historyTable.setItemText(lastRowIndex, 1, h.response.join.length.to_s)
                  @historyTable.setItemText(lastRowIndex, 2, h.request.url) if h.request.respond_to? :url
                  3.times do |i|
                     i = @historyTable.getItem(lastRowIndex, i)
                     i.justify = FXTableItem::LEFT unless i.nil?
                  end
               end
            rescue => bang
               puts bang
            end

         end

         def updateSelection()
            @first_sel_info.clear()
            @second_sel_info.clear()

            if @first_selection

               @first_sel_info.update( :url => @first_selection.request.url,
               :hid => (@history.index(@first_selection) + 1).to_s,
               :status => @first_selection.response.status,
               :length => @first_selection.response.join.length.to_s)

            end

            if @second_selection
               @second_sel_info.update( :url => @second_selection.request.url,
               :hid => (@history.index(@second_selection) + 1).to_s,
               :status => @second_selection.response.status,
               :length => @second_selection.response.join.length.to_s)

            end
         end

         def getDiffChats()
            first = nil
            second = nil
            begin
               case @first_chat_dt.value
               when 0

               when 1

               end

            rescue

               return first, second
            end
         end

         def initialize(owner, opts)
            super(owner, opts)

            @history_size = 10
            @history = []
            @slider_selection = nil
            @first_selection = nil
            @second_selection = nil

            FXMAPFUNC(SEL_COMMAND, DiffFrame::ID_HISTORY_BUTTON, 'onHistoryButton')

            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
            # frame_left = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH, :width => 70, :padding => 0)
            # @history_slider = HistorySlider.new(frame_left, self, @history_size, opts)

            frame_right = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            sunken = FXVerticalFrame.new(frame_right, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @historyTable = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
            initHistoryTable()

            @historyTable.connect(SEL_COMMAND, method(:onTableClick))

            first_chat_gb = FXGroupBox.new(frame_right, "First Chat", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            @first_sel_info = SelectionInfo.new(first_chat_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            second_chat_gb = FXGroupBox.new(frame_right, "Second Chat", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            @second_sel_info = SelectionInfo.new(second_chat_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            diff_button = FXButton.new(frame_right, "Diff it!", nil, nil, 0, :opts => LAYOUT_FILL_X|FRAME_RAISED|FRAME_THICK)

            diff_button.connect(SEL_COMMAND) {
               # new, orig = getDiffChats()
               if @first_selection and @second_selection then
                  first_request = Watobo::Utils.copyObject(@first_selection.request)
                  first_response = Watobo::Utils.copyObject(@first_selection.response)
                  second_request = Watobo::Utils.copyObject(@second_selection.request)
                  second_response = Watobo::Utils.copyObject(@second_selection.response)

                  chat_one = Watobo::Chat.new(first_request, first_response, :id => 0)
                  chat_two = Watobo::Chat.new(second_request, second_response, :id => 0)
                  project = nil
                  diffViewer = ChatDiffViewer.new(FXApp.instance, chat_one, chat_two)
                  diffViewer.create
                  diffViewer.show(Fox::PLACEMENT_SCREEN)
               end
            }
         end
      end

      #
      class ManualRequestSender < Watobo::Session
         def initialize(project)
            @project = project
            super(project.object_id,  project.getScanPreferences())

         end

         def sendRequest(new_request, prefs)
            id = 0
            if prefs[:run_login ] == true
               runLogin(@project.getLoginChats(), prefs)
            end
            #if prefs[:update_session ] == true and
            unless prefs[:update_csrf_tokens] == true
               prefs[:csrf_requests] = []
               prefs[:csrf_patterns] = []
            end

            new_request.extend Watobo::Mixin::Parser::Web10
            new_request.extend Watobo::Mixin::Shaper::Web10
            begin
               test_req, test_resp = self.doRequest(new_request, prefs)
               test_req.extend Watobo::Mixin::Parser::Url
               test_req.extend Watobo::Mixin::Parser::Web10
               test_resp.extend Watobo::Mixin::Parser::Web10
               return test_req,test_resp
            rescue => bang
               puts bang
               puts bang.backtrace if $DEBUG
            end
            return nil, nil
            
         end
      end

      #
      #--------------------------------------------------------------------------------------------
      #
      class ManualRequestEditor < FXDialogBox

         include Watobo::Constants
         include Watobo::Gui::Icons

         include Responder
         # ID_CTRL_S = ID_LAST
         # ID_LAST = ID_CTRL_S + 1
         SCANNER_IDLE = 0x00
         SCANNER_STARTED = 0x01
         SCANNER_FINISHED = 0x02
         SCANNER_CANCELED = 0x04
         def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
         end

         def openCSRFTokenDialog(sender, sel, item)
            csrf_dlg = CSRFTokenDialog.new(self, @project, @chat)
            if csrf_dlg.execute != 0 then
               csrf_ids = csrf_dlg.getTokenScriptIds()
               csrf_patterns = csrf_dlg.getTokenPatterns()

               # puts csrf_ids.to_yaml
               # puts "= = ="
               # puts csrf_patterns.to_yaml

               @project.setCSRFRequest(@original_request, csrf_ids, csrf_patterns)

               @csrf_requests = []
               csrf_ids.each do |id|
                  chat = @project.getChat(id)
                  @csrf_requests.push chat.copyRequest
               end

               # save settings
               #  saveProjectSettings(@active_project)
               #  saveSessionSettings(@active_project)
            end
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

         def onRequestReset(sender,sel,item)
            @req_builder.setRequest(@original_request)
         end

         # def onShowPreview(sender, sel, item)
         #@interface.showPreview(request, response)
         # end

         def logger(message)
          @log_viewer.log( LOG_INFO, message )
          puts "[#{self.class.to_s}] #{message}" if $DEBUG
         end



         def addHistoryItem(request, response, raw_request)
            @history.push HistoryItem.new(request, response, eval(YAML.load(YAML.dump(raw_request.inspect))))

            @history.shift if @history.length > @history_size

            @diff_frame.updateHistory(@history)
         end

         def onBtnQuickScan(sender, sel, item)
            dlg = Watobo::Gui::QuickScanDialog.new(self, @project, :target_chat => @chat, :enable_one_time_tokens => @updateCSRF.checked?)
            scan_chats = []
            if sender.text =~ /Cancel/i
               @scanner.cancel() if @scanner
               logger("QuickScan canceled by user")
                @pbar.progress = 0
               sender.text = "QuickScan"
               return
            end

            if dlg.execute != 0 then
              puts "* Dialog Finished"
               scan_modules = []
               sender.text = "Cancel"
               quick_scan_options = dlg.options
               # puts quick_scan_options.to_yaml

               if quick_scan_options[:use_orig_request] == true then
                  req = @original_request
               else
                  req = @req_builder.parseRequest()
               end

               scan_chats.push Chat.new(req, [""], :id => @chat.id, :run_passive_checks => false)
            end

            unless scan_chats.empty? then
               # we only need array of selected class names
              # scan_modules = dlg.selectedModules().map{ |m| m.class.to_s }
               
              # acc = @project.active_checks.select do |ac|
              #    scan_modules.include? ac.class.to_s
              # end
               log_message = ["QuickScan Started"]
               log_message << "Target URL: #{scan_chats.first.request.url}"
               
               acc = dlg.selectedModules
               
               acc.each do |ac|
                 log_message << "Module: #{ac.info[:check_name]}"
               end

               scan_prefs = @project.getScanPreferences
               # we don't want logout detection during a QuickScan
               # TODO: let this decide the user!
               scan_prefs[:logout_signatures] = [] if quick_scan_options[:detect_logout] == false
               #  scan_prefs[:csrf_requests] = @project.getCSRFRequests(@original_request) if quick_scan_options[:update_csrf_tokens] == true
               scan_prefs[:run_passive_checks] = false

               # logging required ?

               if quick_scan_options[:enable_logging] and quick_scan_options[:scanlog_name]
                  scan_prefs[:scanlog_name] = quick_scan_options[:scanlog_name]
               end
               
               if $DEBUG
                puts "* creating scanner ..."
                puts quick_scan_options.to_yaml
                puts "- - - - - - - - -"
                puts scan_prefs.to_yaml
              end

               @scanner = Watobo::Scanner2.new(scan_chats, acc, @project.passive_checks, scan_prefs)
              
               @pbar.total = @scanner.numTotalChecks
               @pbar.progress = 0
               @pbar.barColor = FXRGB(255,0,0)

               @scanner.subscribe(:progress) { |m|
                  #         print "="
                  @pbar.increment(1)
               }


               @scanner.subscribe(:new_finding) { |f|
                  @project.addFinding(f)
               }
               
               @scanner.subscribe(:module_started){ |m| logger("Module #{m} started")}
               @scanner.subscribe(:module_finished){ |m| logger("Module #{m} finished")}

               csrf_requests = []

               if quick_scan_options[:update_csrf_tokens] == true
                  @project.getCSRFRequestIDs(req).each do |id|
                     chat = @project.getChat(id)
                     csrf_requests.push chat.copyRequest
                  end
                  puts "* Got No CSRF Requests!!" if csrf_requests.empty?
               end

               run_prefs = {
                  :update_sids => @updateSID.checked?,
                  :update_session => @updateSession.checked?,
                  :csrf_requests => csrf_requests,
                  :csrf_patterns => scan_prefs[:csrf_patterns],
                  :www_auth => scan_prefs[:www_auth],
                  :follow_redirect => quick_scan_options[:follow_redirect],
               }
              
              logger("Scan Started ...")
              Watobo.log(log_message, :sender => self.class.to_s.gsub(/.*:/,""))
              
              @scan_status = SCANNER_STARTED
              Thread.new(run_prefs) { |rp|
                  begin
                  # puts "* starting scanner ..."
                  # puts run_prefs.to_yaml
                  
                  @scanner.run( rp )

                    #sender.text = "QuickScan"
                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                  ensure
                   logger("Scan finished!")
                   Watobo.log("QuickScan finished", :sender => self.class.to_s.gsub(/.*:/,""))
                   @scan_status_lock.synchronize do
                      @scan_status |= SCANNER_FINISHED
                   end  
                  end
                 }
            end

            # return 0

         end

         def onBtnSendClick(sender,sel,item)
            sendManualRequest()
         end

         def onPreviewClick(sender,sel,item)
            @request_viewer.setText('')
            new_request = @req_builder.parseRequest
            #  puts "new request: #{new_request}"
            @request_viewer.setText(new_request)
            @tabBook.current = 1
         end

         def showHistory(dist=0, pos=nil)
            if @history.length > 0

               current_pos = @history_pos_dt.value
               new_pos = current_pos + dist
               new_pos = 1 if new_pos <= 0
               new_pos = @history.length if new_pos > @history.length

               @req_builder.setRequest(@history[new_pos-1].raw_request)
               @req_builder.highlight("(%%[^%]*%%)")

               @response_viewer.setText(@history[new_pos-1].response)

               @history_pos_dt.value = new_pos
               @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)
               return new_pos
            end
            return 0 if dist == 0 and not pos
         end

        def initialize(owner, project, chat)
            begin
               # Invoke base class initialize function first

               super(owner, "Manual Request Toolkit", :opts => DECOR_ALL,:width=>850, :height=>600)

               @event_dispatcher_listeners = Hash.new

               @request_sender = ManualRequestSender.new(project)
               @request_sender.subscribe(:follow_redirect){ |loc| logger( "follow redirect -> #{loc}")}
               @responseFilter = FXDataTarget.new("")

               @chat = chat
               
               if chat.respond_to? :request
                 self.title = "#{chat.request.method} #{chat.request.url}"
               end

               @original_request = chat.copyRequest

               @project = project

               @csrf_requests = []

               @tselect = ""
               @sel_pos = ""
               @sel_len = ""

               @last_request = nil
               @last_response = nil

               @history_size = 10
               @history = []
               @counter = 0

               @scanner = nil
               
               @new_response = nil
               @new_request = nil
               
               @update_lock = Mutex.new
               @scan_status_lock = Mutex.new
               @scan_status = SCANNER_IDLE

               # shortcuts here
               #FXMAPFUNC(SEL_COMMAND, ID_CTRL_S, :on_ctrl_s)
               #accelTable.addAccel(fxparseAccel("Ctrl+S"), self, FXSEL(SEL_COMMAND, ID_CTRL_S))

               # @scanlog_dir = @project.scanLogDirectory()

               self.icon = ICON_MANUAL_REQUEST

               # Construct some hilite styles
               hs_red = FXHiliteStyle.new
               hs_red.normalForeColor = FXRGBA(255,255,255,255) # FXColor::Red
               hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
               hs_red.style = FXText::STYLE_BOLD

               mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
               # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
               top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM,:height => 500)
               top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)

               log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)

               #LAYOUT_FILL_X in combination with LAYOUT_FIX_WIDTH

               req_editor = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|FRAME_GROOVE,:width=>400, :height=>500)

               req_edit_header = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X)

               #req_viewer = FXVerticalFrame.new(req_editor, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)

               @req_builder = RequestBuilder.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding=>0)
               @req_builder.subscribe(:hotkey_ctrl_s) {
                  simulatePressSendBtn()
                  sendManualRequest()
               }
               @req_builder.subscribe(:hotkey_ctrl_enter) {
                  simulatePressSendBtn()
                  sendManualRequest()
               }

               @req_builder.subscribe(:error) { |msg| logger(msg)}

               @req_builder.setRequest(@original_request)

               history_navigation = FXHorizontalFrame.new(req_edit_header, :opts => FRAME_NONE)
               FXLabel.new(history_navigation, "History:", :opts => LAYOUT_CENTER_Y )
               hback = FXButton.new(history_navigation, "<", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
               @history_pos_dt = FXDataTarget.new(0)
               @history_pos = FXTextField.new(history_navigation, 2, @history_pos_dt, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
               @history_pos.justify = JUSTIFY_RIGHT
               @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)

               hback.connect(SEL_COMMAND){ showHistory(-1)}
               hnext = FXButton.new(history_navigation, ">", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
               hnext.connect(SEL_COMMAND){ showHistory(1)}

               menu = FXMenuPane.new(self)
               FXMenuCommand.new(menu, "-> GET").connect(SEL_COMMAND, method(:trans2Get))
               FXMenuCommand.new(menu, "-> POST").connect(SEL_COMMAND, method(:trans2Post))
               #  FXMenuCommand.new(menu, "POST <=> GET").connect(SEL_COMMAND, method(:switchMethod))

               req_reset_button = FXButton.new(req_edit_header, "Reset", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_FILL_Y)
               req_reset_button.connect(SEL_COMMAND, method(:onRequestReset))

               # Button to pop menu
               FXMenuButton.new(req_edit_header, "&Transform", nil, menu, (MENUBUTTON_DOWN|FRAME_RAISED|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_RIGHT|LAYOUT_FILL_Y))

               # req_reset_button = FXButton.new(request_frame, "POST -> GET", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
               # req_reset_button.connect(SEL_COMMAND, method(:switchMethod))

               #request_frame = FXHorizontalFrame.new(req_edit_header, :opts => FRAME_GROOVE|LAYOUT_RIGHT)
               # FXLabel.new(request_frame, "Request:", :opts => LAYOUT_CENTER_Y )

               frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :padding => 0)
               req_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
               #eq_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)

               #opt = FXGroupBox.new(req_options, "Request Options", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)

               @settings_tab = FXTabBook.new(req_options, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

               resp_tab = FXTabItem.new(@settings_tab, "Request Options", nil)
               opt= FXVerticalFrame.new(@settings_tab, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

               #  opt = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
               #  btn = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
               #FXCheckButton.new(rob, "URL Encoding", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @updateContentLength = FXCheckButton.new(opt, "Update Content-Length", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @updateContentLength.checkState = true

               @followRedirect = FXCheckButton.new(opt, "Follow Redirects", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @followRedirect.checkState = false

               @logChat = FXCheckButton.new(opt, "Log Chat", nil, 0,
               ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @logChat.checkState = false

               # scan_tab = FXTabItem.new(@settings_tab, "QuickScan Options", nil)
               sess_tab = FXTabItem.new(@settings_tab, "Session Settings", nil)
               session_frame = FXVerticalFrame.new(@settings_tab, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

               @updateSID = FXCheckButton.new(session_frame, "Update SID Cache", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @updateSID.checkState = false

               @updateSession = FXCheckButton.new(session_frame, "Update Session", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @updateSession.checkState = true
               @updateSession.connect(SEL_COMMAND) do |sender, sel, item|
                  @runLogin.enabled = @updateSession.checked?
               end

               @runLogin = FXCheckButton.new(session_frame, "Run Login", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @runLogin.checkState = false

               csrf_frame = FXHorizontalFrame.new(session_frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP, :padding => 0)
               @updateCSRF = FXCheckButton.new(csrf_frame, "Update One-Time-Tokens", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
               @updateCSRF.checkState = false
               @csrf_settings_btn = FXButton.new(csrf_frame, "O-T-T Settings")
               @csrf_settings_btn.connect(SEL_COMMAND, method(:openCSRFTokenDialog))

               @updateCSRF.connect(SEL_COMMAND) do |sender, sel, item|
                  if @updateCSRF.checked? then
                     @csrf_settings_btn.enable
                  else
                     @csrf_settings_btn.disable
                  end
               end

               ##################################################

               ##################################################

               button_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LAYOUT_RIGHT, :width => 100)
               send_frame = FXVerticalFrame.new(button_frame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X, :padding => 2)
               send_frame.backColor = FXColor::Red
               #btn_send = FXButton.new(frame, "\nSEND", ICON_SEND_REQUEST, nil, 0, :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LAYOUT_RIGHT, :width => 100)
               @btn_send = FXButton.new(send_frame, "\nSEND", ICON_SEND_REQUEST, nil, 0, :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_RIGHT)
               btn_prev = FXButton.new(button_frame, "preview >>", nil, nil, 0, :opts => LAYOUT_FILL_X|FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
               btn_prev.connect(SEL_COMMAND,method(:onPreviewClick))

               frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X|FRAME_GROOVE)

               @btn_quickscan = FXButton.new(frame, "QuickScan", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
               @btn_quickscan.connect(SEL_COMMAND, method(:onBtnQuickScan))
               @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
               #@pbar.create
               @pbar.connect(SEL_CHANGED) {
                  print ":"
               }
               @pbar.progress = 0
               @pbar.total = 0
               @pbar.barColor=0
               @pbar.barColor = 'grey' #FXRGB(255,0,0)

               # TODO: Implement font sizing
               #@req_builder.font = FXFont.new(app, "courier" , 14, :encoding=>FONTENCODING_ISO_8859_1)

               result_viewer = FXVerticalFrame.new(top_splitter, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE|LAYOUT_FIX_WIDTH, :width => 400)

               # log_viewer = FXVerticalFrame.new(bottom_frame, :opts => LAYOUT_FILL_X|FRAME_GROOVE|LAYOUT_BOTTOM)

               @tabBook = FXTabBook.new(result_viewer, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

               resp_tab = FXTabItem.new(@tabBook, "Response", nil)
               frame = FXVerticalFrame.new(@tabBook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
               @response_viewer = Watobo::Gui::ResponseViewer.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
               #@response_viewer.ma
               @response_viewer.max_len = 0

               options = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
               frame = FXHorizontalFrame.new(options, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
               frame.backColor = FXColor::White
               label = FXLabel.new(frame, "MD5: ", :opts => LAYOUT_FILL_Y|JUSTIFY_CENTER_Y)
               label.backColor = FXColor::White
               @responseMD5 = FXLabel.new(frame, "-N/A-", :opts => LAYOUT_FILL_Y|JUSTIFY_CENTER_Y)
               @responseMD5.backColor = FXColor::White

               browser_button = FXButton.new(options, "Browser-View", ICON_BROWSER_MEDIUM, nil, 0, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
               browser_button.connect(SEL_COMMAND) {
                  begin
                     if @last_request and @last_response then
                        #@interface.openBrowser(@last_request, @last_response)
                        notify(:show_browser_preview, @last_request, @last_response)
                     end
                  rescue => bang
                     puts bang

                  end
               }

               req_tab = FXTabItem.new(@tabBook, "Request", nil)
               @request_viewer = Watobo::Gui::RequestViewer.new(@tabBook, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

               diff_tab = FXTabItem.new(@tabBook, "Differ", nil)

               @diff_frame = DiffFrame.new(@tabBook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            #   log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
             #  FXLabel.new(log_frame_header, "Logs:" )

               log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
               @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
               #--------------------------------------------------------------------------------

               @btn_send.connect(SEL_COMMAND, method(:onBtnSendClick))

               add_update_timer(50)

            rescue => bang
               puts bang
               puts bang.backtrace if $DEBUG
            end

         end

         private

  def add_update_timer(ms)
  @update_timer = FXApp.instance.addTimeout( ms, :repeat => true) {
    @scan_status_lock.synchronize do
      
      if @scan_status == ( SCANNER_STARTED | SCANNER_FINISHED ) or @scan_status == ( SCANNER_STARTED | SCANNER_CANCELED )
        puts "[SCAN-STATUS] #{@scan_status}"
         @pbar.total = 0
         @pbar.progress = 0
         @pbar.barColor = 'grey'
         @btn_quickscan.text = "QuickScan"
         @scan_status = SCANNER_IDLE
      end
    end
    @update_lock.synchronize do
      unless @new_response.nil? 
        @last_request = nil
        @last_response = nil
        
        @response_viewer.setText @new_response
        @last_response = @new_response

        if @logChat.checked? == true

          chat = Watobo::Chat.new(@new_request, @new_response, :source => CHAT_SOURCE_MANUAL, :run_passive_checks => false)

          notify(:new_chat, chat)
        end
      

      unless @new_request.nil? then
        @request_viewer.setText @new_request
        @last_request = @new_request

        @response_viewer.setText(@new_response, :filter => true)
        @responseMD5.text = @new_response.contentMD5

        addHistoryItem(@new_request, @new_response, @req_builder.rawRequest)

        @history_pos_dt.value = @history.length
        @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      # puts @req_builder.rawRequest
      else
        logger("ERROR: #{@last_response.first}");
        @responseMD5.text = "- N/A -"
      end
      
      @new_request = nil
      @new_response = nil
      
      end
    end
    
  }
end
         
         def sendManualRequest
            @request_viewer.setText('')
            @response_viewer.setText('')
            new_request = @req_builder.parseRequest
            
            if new_request.nil?
               logger("Could not send request!")
               return false
            end
           

            if @updateCSRF.checked?
               @csrf_requests = []
               @project.getCSRFRequestIDs(new_request).each do |id|
                  chat = @project.getChat(id)
                  @csrf_requests.push chat.copyRequest

               end
            end

            prefs = {:run_login => @updateSession.checked? ? @runLogin.checked? : false,
               :update_session => @updateSession.checked?,
               :update_contentlength => @updateContentLength.checked?,
               :update_csrf_tokens => @updateCSRF.checked?,
               :csrf_requests => @csrf_requests,
               :csrf_patterns => @project.getCSRFPatterns(),
               :update_sids => @updateSID.checked?,
               :follow_redirect => @followRedirect.checked?
            }

            prefs.update @project.getScanPreferences
            #  puts "=== Scan Preferences"
            #  puts prefs.to_yaml

             @request_thread = Thread.new(new_request, prefs) { |nr, p|
            #nr = new_request
            #p = prefs

            begin
               logger("send request")
             #  puts p.to_yaml
               last_request, last_response = @request_sender.sendRequest(nr, p )
               
               logger("got answer")
               

=begin
               if last_request and p[:follow_redirect] == true and last_response.status =~ /302/
                  if @logChat.checked? == true
                     chat = Watobo::Chat.new(last_request, last_response, :source => CHAT_SOURCE_MANUAL, :run_passive_checks => false)
                     notify(:new_chat, chat)
                  end
                  #   puts "* Following redirect"

                  loc_header = last_response.headers("Location:").first
                  new_location = loc_header.gsub(/^[^:]*:/,'').strip
                  unless new_location =~ /^http/
                     new_location = last_request.proto + "://" + last_request.site + "/" + last_request.dir + "/" + new_location.sub(/^[\.\/]*/,'')
                  end
                  logger("follow redirect: #{new_location}")
                  # create GET request for new location
                  nr.replaceMethod("GET")
                  nr.removeHeader("Content-Length")
                  nr.removeBody()
                  nr.replaceURL(new_location)
                  # puts nr.first
                  last_request, last_response = @request_sender.sendRequest(nr, p )
                  logger("got answer")
               end
=end               
               @new_request = last_request
               @new_response = last_response
               
            rescue => bang
               puts bang

            end            
              }

         end

         def trans2Get(sender, sel, item)
            request = @req_builder.parseRequest
            return nil if request.nil?
            @project.extendRequest(request)

            #  puts sender.methods.sort
            #  puts sel
            #  puts item

            if request.method =~ /POST/i
               request.setMethod("GET")
               request.removeHeader("Content-Length")
               data = request.data
               #      puts "Data: "
               #      puts data
               request.appendQueryParms(data)
               request.setData('')
            end
            @req_builder.setRequest(request)
         end

         def trans2Post(sender, sel, item)
            request = @req_builder.parseRequest
            return nil if request.nil?
            @project.extendRequest(request)

            #    puts sender.methods.sort
            #    puts sel
            #    puts item
            if request.method =~ /GET/i
               request.setMethod("POST")
               request.addHeader("Content-Length", "0")
               data = request.query
               request.setData(data)
               request.removeUrlParms()

            end
            @req_builder.setRequest(request)
         end

         def simulatePressSendBtn()
            Thread.new{
               @btn_send.state = STATE_DOWN
               sleep 0.1
               @btn_send.state = STATE_UP
            }
         end

         def hide()
            @scanner.cancel() if @scanner
            super
         end

      end
   end
end
