# .
# filefinder.rb
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
    module Filefinder
      
      class Check < Watobo::ActiveCheck
        attr_accessor :db_file
        attr_accessor :path
        attr_accessor :append_slash        
        
        
        def add_extension(ext)
          ext.gsub!(/^\.+/,"")
          @extensions << ext
        end
        
        def set_extensions(extensions)
          @extensions = extensions if extensions.is_a? Array
          @extensions << nil
        end
        
        def initialize(project, file, prefs)
          super(project, prefs)
          
          @info.update(
                       :check_name => 'File Finder',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Test list of file names.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Hidden files may reveal sensitive information or can enhance the attack surface.',        # thread of vulnerability, e.g. loss of information
          :class => "Hidden-File",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_LOW 
          )
          @path = nil 
          @db_file = file
          @prefs = prefs
          @extensions = [ nil ]
          @append_slash = false
        end
        
        
        
        def reset()
          # @catalog_checks.clear
        end
        
        def generateChecks(chat)
          begin
            puts "* generating checks for #{@db_file} ..."
            content = [ @db_file ]
            content = File.open(@db_file) if File.exist?(@db_file)
            
            content.each do |uri|
             # puts "+ #{uri}"
            @extensions.each do |ext|  
             # puts "  + #{ext}"
              next if uri.strip =~ /^#/
              # cleanup dir
              uri.strip!
              uri.gsub!(/^[\/\.]+/,'')
              uri.gsub!(/\/$/,'')
              next if uri.strip.empty?
             
              checker = proc {
                test_request = nil
                test_response = nil
                # !!! ATTENTION !!!
                # MAKE COPY BEFORE MODIFIYING REQUEST 
                test = chat.copyRequest
                new_uri = "#{uri}"
                unless ext.nil? or ext.empty?
                  new_uri << ".#{ext}"                 
                  end 
                new_uri << "/" if @append_slash == true
               # puts ">> #{new_uri}"
                test.replaceFileExt(new_uri)
               # puts test.url
                status, test_request, test_response = fileExists?(test, @prefs)
                
                
                if status == true
                  
                  puts "FileFinder >> #{test.url}"
                  
                  addFinding(  test_request, test_response,
                             :test_item => new_uri,
                            # :proof_pattern => "#{Regexp.quote(uri)}",
                  :check_pattern => "#{Regexp.quote(new_uri)}",
                  :chat => chat,
                  :threat => "depends on the file ;)",
                  :title => "[#{new_uri}]"
                  
                  )
                  
                end
                
                # notify(:db_finished)
                [ test_request, test_response ]
              }
              yield checker
            end
            end
          rescue => bang
            puts "!error in module #{Module.nesting[0].name}"
            puts bang
          end
        end
      end
      
      class Filefinder < Watobo::Template::Plugin
        
          include Watobo::Constants
        class DBSelectFrame < FXVerticalFrame
          
          def select_db(db_name)
            @db_listbox.numItems.times do |i|
              if db_name == @db_listbox.getItemData(i)
                @db_listbox.currentItem = i
              end
            end            
          end
          
          def get_db_name
            i = @db_listbox.currentItem
            db = ''
            db = @db_listbox.getItemData(i) if i >= 0
            db
          end
          
          def get_db_list
            l = []
            @db_listbox.numItems.times do |i|
              l << @db_listbox.getItemData(i)
            end
            l
          end
          
          def initialize(parent, db_list, opts)
            super(parent, opts)
            @db_list = []
            db_list.each do |f|
              @db_list << f if File.exist? f
            end
           
            FXLabel.new(self, "Each filename must be in a seperate line, e.g. DirBuster-DBs" )
            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
            
            @db_listbox = FXListBox.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK)
            @db_list.each do |db|
              item = @db_listbox.appendItem(db)
              @db_listbox.setItemData(@db_listbox.numItems-1, db )
            end
            @db_listbox.numVisible = @db_listbox.numItems
            
            @add_db_btn = FXButton.new(frame, "add")
            @add_db_btn.connect(SEL_COMMAND) { add_db }
          end
          
          private
          
          def add_db
            db_path = File.dirname(get_db_name)
          db = FXFileDialog.getOpenFilename(self, "Open DB", db_path, "All Files (*)")
          unless db.empty?
            item = @db_listbox.appendItem(db)
            i= @db_listbox.numItems-1
              @db_listbox.setItemData(i, db )
              @db_listbox.currentItem = i
          end
        end
        end
        
        def updateView()
          #@project = project
          @sites_combo.clearItems()
          @dir_combo.clearItems()
          @dir_combo.disable
          
          if @project then
            @sites_combo.appendItem("no site selected", nil)
            @project.listSites(:in_scope => Watobo.project.has_scope? ).each do |site|
              #puts "Site: #{site}"
              @sites_combo.appendItem(site.slice(0..35), site)
            end
            @sites_combo.setCurrentItem(0) if @sites_combo.numItems > 0
            ci = @sites_combo.currentItem
            site = ( ci >= 0 ) ? @sites_combo.getItemData(ci) : nil
             @sites_combo.numVisible = @sites_combo.numItems
            @sites_combo.numColumns = 35
            
            if site
              @dir_combo.enable
              @project.listDirs(@site) do |dir|
                @dir_combo.appendItem(dir.slice(0..35), dir)
              end
              @dir_combo.setCurrentItem(0, true) if @dir_combo.numItems > 0
              
            end
          end
          
        end
        
        def onClose
          
        end
        
        
        def initialize(owner, project)
          super(owner, "File Finder", project, :opts => DECOR_ALL, :width=>800, :height=>600)
          load_icon(__FILE__)
          
          self.connect(SEL_CLOSE, method(:onClose))
          
          @event_dispatcher_listeners = Hash.new
          @scanner = nil
          @plugin_name = "File-Finder"
          @project = project
          @path = Dir.getwd
          
          
          @site = nil
          @dir = nil
          @db_list = []
          @db_name = ""
          @file_name = ""
          
          config = load_config

          
          if config.respond_to? :has_key?
          if config.has_key? :db_list
            config[:db_list].each do |db|
              @db_list << db if File.exist? db              
            end
          end
          
          if config.has_key? :name
            @db_list.each do |db|
              @db_name = db if config[:name] == db
            end
            @file_name = config[:name] if @db_name.empty?            
          end
          end
          puts @db_list
          
          begin            
            hs_green = FXHiliteStyle.new
            hs_green.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
            hs_green.normalBackColor = FXRGBA(0,255,0,1)   # FXColor::White
            hs_green.style = FXText::STYLE_BOLD
            
            hs_red = FXHiliteStyle.new
            hs_red.normalForeColor = FXRGBA(255,255,255,255) # FXColor::Red
            hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
            hs_red.style = FXText::STYLE_BOLD
            
            
            path = Dir.getwd
            
            mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
            # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
            top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM,:height => 500) 
            top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
            log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)
            
            @settings_tab = FXTabBook.new(top_splitter, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
             FXTabItem.new(@settings_tab, "Settings", nil)
            @settings_frame = FXVerticalFrame.new(@settings_tab, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_Y|FRAME_RAISED)
            
            FXTabItem.new(@settings_tab, "Logging", nil)
            @logging_frame = FXVerticalFrame.new(@settings_tab, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_Y|FRAME_RAISED)
            
             request_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
             @requestCombo = FXComboBox.new(request_frame, 5, nil, 0,
                                           COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            #@filterCombo.width =200
            
            @requestCombo.numVisible = 0
            @requestCombo.numColumns = 50
            @requestCombo.editable = false
            @requestCombo.connect(SEL_COMMAND, method(:onSelectRequest))
            
            log_text_frame = FXVerticalFrame.new(request_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            @request_editor = RequestEditor.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            
           #   @scope_only_cb = FXCheckButton.new(@settings_frame, "target scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
           # @scope_only_cb.setCheck(false)
           # @scope_only_cb.connect(SEL_COMMAND) { updateView() }
            
            FXLabel.new(@settings_frame, "Select Site:")
            @sites_combo = FXComboBox.new(@settings_frame, 5, nil, 0,
                                          COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            #@filterCombo.width =200
            
            @sites_combo.numVisible = 20
            @sites_combo.numColumns = 35
            @sites_combo.editable = false
            @sites_combo.connect(SEL_COMMAND, method(:onSiteSelect))
            
            
            
            FXLabel.new(@settings_frame, "Root Directory:")
            @dir_combo = FXComboBox.new(@settings_frame, 5, nil, 0,
                                        COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            @dir_combo.numVisible = 20
            @dir_combo.numColumns = 35
            @dir_combo.editable = false
            @dir_combo.connect(SEL_COMMAND, method(:onDirSelect))
            
            @test_all_dirs = FXCheckButton.new(@settings_frame, "test all sub-directories", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            @test_all_dirs.setCheck(false)
            
            
            @finder_tab = FXTabBook.new(@settings_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            
            FXTabItem.new(@finder_tab, "Filename", nil)
            frame = FXVerticalFrame.new(@finder_tab, :opts => LAYOUT_FILL_X|FRAME_RAISED)
            @search_name_dt = FXDataTarget.new(@file_name)
           
            @dbfile_text = FXTextField.new(frame, 30,
                                           :target => @search_name_dt, :selector => FXDataTarget::ID_VALUE,
                                           :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
            @dbfile_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            

            FXTabItem.new(@finder_tab, "Database", nil)     
            @db_select_frame = DBSelectFrame.new(@finder_tab, @db_list, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X)
            
            unless @db_name.empty?
              @db_select_frame.select_db @db_name
              @finder_tab.current = 1
            end
            
            @fmode_dt = FXDataTarget.new(0)
            group_box = FXGroupBox.new(@settings_frame, "Mode", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            mode_frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X)
            @append_slash_cb = FXCheckButton.new(mode_frame, "append /", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_FILL_Y)
           
            @append_extensions_cb = FXCheckButton.new(mode_frame, "append extensions", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_FILL_Y)
            frame = FXVerticalFrame.new(mode_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @extensions_text = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
            ext = "bak;php;asp;aspx;tgz;tar.gz;gz;tmp;temp;old;_"        
            
            @extensions_text.setText(ext)
            
            frame = @logging_frame
            @logScanChats = FXCheckButton.new(frame, "enable", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @logScanChats.checkState = false

            @logScanChats.connect(SEL_COMMAND) do |sender, sel, item|
              if @logScanChats.checked? then
                @scanlog_name_text.enabled = true
                @scanlog_name_text.backColor = FXColor::White
              else
                @scanlog_name_text.enabled = false
                @scanlog_name_text.backColor = @scanlog_name_text.parent.backColor 
              end
            end

            @scanlog_name_dt = FXDataTarget.new('')
           # @scanlog_name_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())
            @scanlog_dir_label = FXLabel.new(frame, "Scan Name:" )
            scanlog_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            @scanlog_name_text = FXTextField.new(scanlog_frame, 20,
            :target => @scanlog_name_dt, :selector => FXDataTarget::ID_VALUE,
            :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
            @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            unless @logScanChats.checked?
              @scanlog_name_text.enabled = false
              @scanlog_name_text.backColor = @scanlog_name_text.parent.backColor
            end 
             
            
            @pbar = FXProgressBar.new(@settings_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)
            
            @speed = FXLabel.new(@settings_frame, "Requests per second: 0")
            
            @start_button = FXButton.new(@settings_frame, "start")
            @start_button.connect(SEL_COMMAND, method(:start))
            @start_button.disable
            
            log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
            FXLabel.new(log_frame_header, "Logs:" )
            
            log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            
            updateView()
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
        
        def create
          super
          
          @log_viewer.purge_logs
          @request_editor.setText('')
          @requestCombo.clearItems()
          @start_button.text = "Start"
                   # Create the windows
          show(PLACEMENT_SCREEN) # Make the main window appear
          disableOptions()
        end
        
       
        
        private
        
        def config
          name = @search_name_dt.value
          db_list = @db_select_frame.get_db_list
          if @finder_tab.current == 1
            name = @db_select_frame.get_db_name           
          end
          
          c={
            :db_list => db_list,
            :name => name            
          }
          
        end
        
        def onSelectRequest(sender, sel, item)
          begin
            chat = @requestCombo.getItemData(@requestCombo.currentItem)
            updateRequestEditor(chat)
          rescue => bang
            puts "could not update request"
            puts bang
          end
        end
        
        def updateRequestCombo(chat_list)
          @requestCombo.clearItems()
          chat_list.each do |chat|
            text = "[#{chat.id}] #{chat.request.url}"
            @requestCombo.appendItem(text.slice(0..60), chat)  
          end
          if @requestCombo.numItems > 0 then
            if @requestCombo.numItems < 10 then
              @requestCombo.numVisible = @requestCombo.numItems
            else
              @requestCombo.numVisible = 10
            end
            @requestCombo.setCurrentItem(0, true)
            chat = @requestCombo.getItemData(0)
          end
          
        end
        
         def updateRequestEditor(chat=nil)
          @request_editor.setText('')
          return if chat.nil?
          #chat = createChat(site, dir)
          #@request_box.setText(chat)
          request = chat.copyRequest
        #  request.replaceFileExt('')
          @request_editor.setText(request.join.gsub(/\r/,""))
        end
        
        def createChat()
          request = @request_editor.parseRequest()
          chat = Watobo::Chat.new(request, [], :id => 0)
        end        
        
         def onSiteSelect(sender, sel, item)
          ci = @sites_combo.currentItem
          @request_editor.setText('')
          @requestCombo.clearItems()
          
          @dir_combo.clearItems()
          @dir = ""
                    
          if ci > 0 then 
            @site = @sites_combo.getItemData(ci)
            if @site
              @dir_combo.appendItem("/", nil)
              
              chats = @project.findChats(@site, :method => "GET")
              updateRequestCombo(chats)
              updateRequestEditor(chats.first)
              if @project then            
                @project.listDirs(@site) do |dir|
                  text = "/" + dir.slice(0..35)
                  text.gsub!(/\/+/, '/')
                  @dir_combo.appendItem(text, dir)
                end
                @dir_combo.setCurrentItem(0, true) if @dir_combo.numItems > 0 
              end
            end
            enableOptions()
            @dir_combo.enable
            @start_button.enable
          else
            @site = nil
            @request_editor.setText('')
            disableOptions()
            @start_button.disable
          end
        end
        
        def disableOptions()
          #  @use_ssl.setCheck(false)
          #  @use_ssl.disable
          @test_all_dirs.setCheck(false)
          @test_all_dirs.disable
          # @run_passive_checks.setCheck(false)
          @dir_combo.disable
          #@run_passive_checks.disable   
          @request_editor.enabled = false
          @request_editor.backColor = FXColor::LightGrey        
        end
        
        def enableOptions()          
          #  @use_ssl.enable          
          @test_all_dirs.enable
          @dir_combo.enable
          @request_editor.enabled = true
          @request_editor.backColor = FXColor::White 
          #@run_passive_checks.enable           
        end
        
       def onDirSelect(sender, sel, item)
          
          
          ci = @dir_combo.currentItem       
          
          if ci > 0  then
            @dir = @dir_combo.getItemData(ci)
          else
            @dir = ""
          end
            chats = @project.findChats(@site, :method => "GET", :dir => @dir)
              updateRequestCombo(chats)
              updateRequestEditor(chats.first)           
        end
        
        
        
        
        
        def hide()
          
          #puts "* #{self.class} closed"
          @scanner.cancel() if @scanner
          
        super
          
        end
        
        def start(sender, sel, item)
          if @start_button.text =~ /cancel/i then
            @scanner.cancel()
            @start_button.text = "Start"
            @pbar.progress = 0
            return
          end
          @start_button.text = "Cancel"
          chatlist = []
          checklist = []
          #config = { :db_file => @dbfile_dt.value }
          save_config(config)
          name = ''
          if @finder_tab.current == 0
            name = @search_name_dt.value
          else
            name = @db_select_frame.get_db_name
          end
                    
          
          @check = Check.new(@project, name, @project.getScanPreferences())
          
          if @append_extensions_cb.checked?
          extensions = @extensions_text.text.split(/(;|\n)/).select {|x| x !~ /(\n|;)/ }          
          @check.set_extensions(extensions) 
          end
          
          @check.append_slash = @append_slash_cb.checked?
          
                  
          @check.path = @path
          
          checklist.push @check
          @check.resetCounters()
          
          @log_viewer.log(LOG_INFO, "Starting ...")
          puts "Site: #{@site}"
       
          @progress_window = Watobo::Gui::ProgressWindow.new(self)
          
       
          @progress_window.show(PLACEMENT_SCREEN)
         t = Thread.new{ 
            begin
              c=1
              if @test_all_dirs.checked? then
                c = 0
                @project.listDirs(@site, :base_dir => @dir, :include_subdirs => @test_all_dirs.checked?) { c += 1 }
                @progress_window.update_progress( :title => "File Finder Plugin", :total => c, :job => @dir)
                @project.listDirs(@site, :base_dir => @dir, :include_subdirs => @test_all_dirs.checked?) do |dir|
                  m = "running checks on #{dir}"            
                  @log_viewer.log(LOG_INFO,m)
                  chat = createChat()
                  
                  chat.request.replaceFileExt('')
                  chat.request.setDir(dir)
                  chatlist.push chat
                  # @check.getCheckCount(chat)
                  @check.updateCounters(chat)
                  @progress_window.update_progress(:increment => 1)
                end
              else
                notify(:update_progress, :total => c, :job => @dir)
                m = "running checks on #{@dir}"            
                @log_viewer.log(LOG_INFO,m)
                chat = createChat()
                chatlist.push chat
                @check.updateCounters(chat)
                @progress_window.update_progress(:increment => 1)
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            ensure
              @progress_window.hide
            end
          }
          
         
          t.join
          
          scan_prefs = Watobo.project.getScanPreferences
          if @logScanChats.checked?
            scan_prefs[:scanlog_name] = @scanlog_name_dt.value unless @scanlog_name_dt.value.empty?
          end
          
          @scanner = Watobo::Scanner2.new(chatlist, checklist, @project.passive_checks, scan_prefs)
          @pbar.total = @check.numChecks
          @pbar.progress = 0
          @pbar.barColor = 'red' 
          
          speed = 0
          lasttime = 0
          @scanner.subscribe(:progress) { |m|
            time = Time.now.to_i
            if time == lasttime then
              speed += 1
            else
              @speed.text = "Requests per second: #{speed}"
              speed = 1
              lasttime = time
            end
            @pbar.increment(1)
          }
          
          @scanner.subscribe(:new_finding) { |f|
            Thread.new { @project.addFinding(f) }
          } 
          
          m= "Total Requests: #{@check.numChecks}"
          @log_viewer.log(LOG_INFO,m)
          
          Thread.new {   
            begin
              m = "start scanning..."
              @log_viewer.log(LOG_INFO,m)
              scan_prefs = @project.getScanPreferences()
              scan_prefs[:run_passive_checks] = false
              @scanner.run(scan_prefs)
              m = "scanning finished!"
              @log_viewer.log(LOG_INFO,m)
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
            @pbar.progress = 0
            @pbar.barColor = 'grey'
            @speed.text = "Requests per second: 0"
            @start_button.text = "Start"
          }
        end
        
      end
    end
  end
end


if __FILE__ == $0
  puts "Running #{__FILE__}"
  catalog = Watobo::Plugin::Catalog.new(project)
end
