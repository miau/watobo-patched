# .
# catalog.rb
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
    module Catalog
      
      class About < FXDialogBox
      def initialize(owner, text)
        super(owner, "About Catalog-Scanner", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE|DECOR_RESIZE,:width=>400, :height=>300)
        self.icon = Watobo::Gui::Icons::ICON_WATOBO
        
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :padding => 0)
        main.backColor = FXColor::White
        
        about_txt = FXText.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        about_txt.editable = false
                                    
about_txt.disable                                    
        about_txt.setText text
        about_txt.font = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD) 
        about_txt.backColor = FXColor::White
        
        bottom = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        FXButton.new(bottom, "OK" ,
        :target => self, :selector => FXDialogBox::ID_ACCEPT,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        
      end 
    end
      
      class Check < Watobo::ActiveCheck
        attr_writer :db_files
        attr_writer :var_files
        attr_writer :path
        
        def loadVars(path)
          dbpath = Dir.getwd
          dbpath = path if not path.nil?
          @dbvars.clear
          @var_files.each do |file|
            # puts "* loading var-file #{file}"
            fname = File.join( dbpath, file)
            if File.exists?(fname)
              File.open(fname) { |fh|
                fh.each do |line|
                  if line.strip =~ /^[^#]/ and line =~ /=/
                    key,vars = line.split("=")
                    key.strip!

                    @dbvars[key] = vars.strip.split(" ")
                  end
                end
              }
            else
              puts "* file (#{fname}) does not exist. Please check path and name."
            end
            # puts "* db vars total: #{@dbvars.length}"
          end
        end

        def loadDBFiles(path, *opts)
          dbpath = Dir.getwd
          dbpath = path if not path.nil?
          @catalog_checks.clear

          @db_files.each do |file|
            # puts "* loading db file #{file}.."
            fname = File.join( dbpath, file)
            if File.exists?(fname)
              File.open(fname) { |fh|
                fh.each do |line|

                  next if line.strip =~ /^#/
                  # puts "+ #{line}"
                  fields = line.split("\",")
                  fields.map!{ |f| f.gsub!(/^"/,'') }
                  fields.first.gsub!(/^\"/,"")
                  fields.last.gsub!(/\"?/,"")
                  #  puts fields.join(" : ")
                  #   puts "*" + fields.length.to_s
                  #  gets
                  @catalog_checks.push fields
                end
              }
              # puts "* db checks total: #{@catalog_checks.length}"
            else
              puts "* file (#{fname}) does not exist. Please check path and name."
            end
          end
        end

        def loadChecks(path)
          begin
            puts "=== Initialize Catalog Scanner ==="
            loadVars(path)
            loadDBFiles(path)
            # setup regex
            dummy = []
            pattern = nil
            count = 0
            @dbvars.each_key do |k| dummy << k; end
            pattern = "(#{dummy.join("|")})" if dummy.length > 0
            @catalog_checks.each do |dbid, osvdb, threat, uri, method, match, or_match, and_match, fail, or_fail, summary, post_data, headers|

              if pattern and uri =~ /(#{pattern})/
                key = $1
                #puts "+ found var key: #{key}"
                @dbvars[key].each do |v|
                  # puts "--#{v}"
                  new_uri = uri.gsub(/#{key}/, v)
                  #count += 1
                  #print "\r[Plugin] Total Checks. #{count}          "
                  yield dbid, osvdb, threat, new_uri, method, match, or_match, and_match, fail, or_fail, summary, post_data, headers
                end
              else
                #count += 1
                #print "\r[Plugin] Total Checks. #{count}          "
                yield dbid, osvdb, threat, uri, method, match, or_match, and_match, fail, or_fail, summary, post_data, headers
              end
            end
            #puts "[Plugin] Total Checks. #{count}"
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def initialize(project)
          super(project, project.getScanPreferences())

          @info.update(
          :check_name => 'Catalog-Scan',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Using catalog databases for testing the web application.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )

          @finding.update(
          :threat => 'catalog db finding',        # thread of vulnerability, e.g. loss of information
          :class => "Catalog",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_LOW
          )

          @path = nil

          @dbvars = Hash.new

          @catalog_checks = []

          @db_files = %w( db_tests )
          @var_files = %w( db_variables )

          @threat_list = [ "File Upload", "Interesting File", "Misconfiguration", "Information Disclosure", "Injection (XSS/Script/HTML)",
            "Remote File Retrieval", "Denial of Service", "Remote File Retrieval", "Command Execution", "SQL Injection",
            "Authentication Bypass", "Software Identification", "Remote source inclusion" ]

        end

        def reset()
          @catalog_checks.clear
        end

        def generateChecks(chat)
          begin
            loadChecks(@path) do |dbid, osvdb, threat, uri, method, match, or_match, and_match, fail, or_fail, summary, post_data, headers|

              checker = proc {
                test_request = nil
                test_response = nil
                # !!! ATTENTION !!!
                # MAKE COPY BEFORE MODIFIYING REQUEST
                test = chat.copyRequest
                test.replaceFileExt(uri.gsub(/^\//,''))

                if method !~ /get/i then
                  test.replaceMethod(method)
                end

                if method =~ /post/i then
                  test.addHeader("Content-Length", "0")
                end

                status, test_request, test_response = fileExists?(test, :default => true)
                # puts "[#{status}] - #{test_request.url}"
                unless test_request.nil? or test_response.nil? then
                  test_result = false
                  response = test_response.join
                  if status == true

                    if ( ( match != "" and response =~ /#{Regexp.quote(match)}/i) or ( or_match != "" and response =~ /#{Regexp.quote(or_match)}/i )) then
                      test_result = true
                      if and_match != "" then
                        test_result = false
                        test_result = true if response =~ /#{Regexp.quote(and_match)}/i

                      end
                    end
                    test_result = false if fail != "" and response =~ /#{Regexp.quote(fail)}/i
                    test_result = false if or_fail != "" and response =~ /#{Regexp.quote(or_fail)}/i

                    # test_chat = Chat.new(test_request, test_response, chat.id)

                    if test_result then
                      #  path = test_request.url.gsub(/#{uri}/,"")
                      path = test_request.path
                      addFinding(  test_request, test_response,
                      :test_item => uri,
                      :proof_pattern => "#{Regexp.quote(match)}",
                      :check_pattern => "#{Regexp.quote(uri)}",
                      :chat => chat,
                      :threat => "#{summary}",
                      :title => "[#{uri}] - #{path}"

                      )

                    end
                  end
                end

                # notify(:db_finished)
                [ test_request, test_response ]
              }
              yield checker
            end
          rescue => bang
            puts "!error in module #{Module.nesting[0].name}"
            puts bang
          end
        end
      end

      class Catalog < Watobo::Template::Plugin
        
        include Watobo::Constants
        
        def updateView()
          #@project = project
          @sites_combo.clearItems()
          @dir_combo.clearItems()
          @dir_combo.disable

          if @project then
            @sites_combo.appendItem("no site selected", nil)
            @project.listSites(:in_scope => Watobo.project.has_scope? ).each do |site|
              #puts "Site: #{site}"
              site_string = site
              if site.length > 60
                site_string = site.slice(0..55)
                site_string << "...:"
                site_string << site.gsub(/.*:/,'')
              end
              @sites_combo.appendItem(site_string, site)
            end
            @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
            @sites_combo.setCurrentItem(0) if @sites_combo.numItems > 0
            ci = @sites_combo.currentItem
            site = ( ci >= 0 ) ? @sites_combo.getItemData(ci) : nil

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
          
          super(owner, "Catalog Scanner", project, :opts => DECOR_ALL, :width=>800, :height=>600)
          menu_bar = FXMenuBar.new(self, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X|FRAME_GROOVE)
          menu_pane = FXMenuPane.new(self)
          
          text = "Catalog-Scanner will test the web application for known directories and/or files.\nYou need two files (db_tests and db_variables) in the DB folder. "
          text << "These files must have the same format as nikto DB files (http://cirt.net/nikto2).\nSo, if you have your own DB files, you"
          text << " can use them with this plugin."
            
        load_icon(__FILE__)
       
        FXMenuTitle.new(menu_bar, "Help" , :popupMenu => menu_pane)
        menu = FXMenuCommand.new(menu_pane, "About" )
        menu.connect(SEL_COMMAND) { 
          dlg = Watobo::Plugin::Catalog::About.new(self, text)
          dlg.execute
          }
        
          self.connect(SEL_CLOSE, method(:onClose))

          @event_dispatcher_listeners = Hash.new
          @scanner = nil
          @plugin_name = "Catalog-Scan"
          @project = project
          
          
         
          @site = nil
          @dir = nil

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
            top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM, :height => 500)
          #   info_frame = FXGroupBox.new(top_frame, "Info", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
         #   info = FXText.new(info_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
         #   info.setText text
         #   info.backColor = info.parent.backColor
         #   info.disable
            top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
            log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)

            @settings_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_Y, :padding => 0)
            #request_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
              request_frame = FXGroupBox.new(top_splitter, "Request Template", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
              FXLabel.new(request_frame, "Select a request template from drop-down list or enter manually.")
            @requestCombo = FXComboBox.new(request_frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            #@filterCombo.width =200

            @requestCombo.numVisible = 0
            @requestCombo.numColumns = 50
            @requestCombo.editable = false
            @requestCombo.connect(SEL_COMMAND, method(:onSelectRequest))

            #log_text_frame = FXVerticalFrame.new(request_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            # @request_box = FXText.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            #   @request_box.styled = true
            # Set the styles
            #  @request_box.hiliteStyles = [ hs_green, hs_red]

            @request_editor = RequestEditor.new(request_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)

          #  FXLabel.new(@settings_frame, "Select Site:")
            ts_frame = FXGroupBox.new(@settings_frame, "Scan Settings", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)

           # @scope_only_cb = FXCheckButton.new(@settings_frame, "target scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
           # @scope_only_cb.setCheck(false)
           # @scope_only_cb.connect(SEL_COMMAND) { updateView() }

            @sites_combo = FXComboBox.new(ts_frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            #@filterCombo.width =200

            @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
            @sites_combo.numColumns = 35
            @sites_combo.editable = false
            @sites_combo.connect(SEL_COMMAND, method(:onSiteSelect))

            FXLabel.new(ts_frame, "Root Directory:")
            @dir_combo = FXComboBox.new(ts_frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            @dir_combo.numVisible = 20
            @dir_combo.numColumns = 35
            @dir_combo.editable = false
            @dir_combo.connect(SEL_COMMAND, method(:onDirSelect))

            @test_all_dirs = FXCheckButton.new(ts_frame, "test all sub-directories", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            @test_all_dirs.setCheck(false)

            # @use_ssl = FXCheckButton.new(@settings_frame, "use SSL", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)

            #   @run_passive_checks = FXCheckButton.new(@settings_frame, "run passive checks", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
            #   @run_passive_checks.setCheck(false)

            frame = FXGroupBox.new(@settings_frame, "Logging", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            @logScanChats = FXCheckButton.new(frame, "enable", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @logScanChats.checkState = false

            @logScanChats.connect(SEL_COMMAND) do |sender, sel, item|
              if @logScanChats.checked? then
                @scanlog_dir_text.enabled = true
                @scanlog_dir_text.backColor = FXColor::White
              #  @scanlog_dir_label.enabled = true
              #  @scanlog_dir_btn.enable
              else
                @scanlog_dir_text.enabled = false
                @scanlog_dir_text.backColor = @scanlog_dir_text.parent.backColor 
              #  @scanlog_dir_label.enabled = false
              #  @scanlog_dir_btn.disable
              end
            end

            @scanlog_dir_dt = FXDataTarget.new('')
           # @scanlog_dir_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())
            @scanlog_dir_label = FXLabel.new(frame, "Scan Name:" )
            scanlog_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            @scanlog_dir_text = FXTextField.new(scanlog_frame, 20,
            :target => @scanlog_dir_dt, :selector => FXDataTarget::ID_VALUE,
            :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
            @scanlog_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            unless @logScanChats.checked?
              @scanlog_dir_text.enabled = false
              @scanlog_dir_text.backColor = @scanlog_dir_text.parent.backColor
            end 
            #@scanlog_dir_btn = FXButton.new(scanlog_frame, "Change")
           # @scanlog_dir_btn.connect(SEL_COMMAND, method(:selectScanlogDirectory))
           
         
          @db_files = %w( db_tests db_variables )
          
          @path = File.expand_path(File.dirname(__FILE__))
          
          
          @known_db_paths = [                             
                          #   File.expand_path(File.dirname(__FILE__)), 
                            # "/pentest/web/nikto/plugins" # BackTrack
                            @path
                             ]
          config = load_config
          unless config.nil?
            if config.has_key? :path_history
              begin
              config[:path_history].each do |p|
                @known_db_paths << p unless @known_db_paths.include? p
              end
              rescue => bang
                puts "!Broken Path History"                
              end
            end
              @path = config[:db_path] if config.has_key? :db_path              
            
          end                   
         
           frame = FXGroupBox.new(@settings_frame, "DB Path", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            #FXLabel.new(frame, "Path:" )
            db_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
             @db_path_combo = FXComboBox.new(db_frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            
            @db_path_combo.numVisible = 3
            @db_path_combo.numColumns = 8
            
            @db_path_combo.editable = false
            @db_path_combo.connect(SEL_COMMAND){
              path = @db_path_combo.getItemData(@db_path_combo.currentItem)
              set_db_path path
            }
           # @db_path_txt = FXTextField.new(db_frame, 20, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
           # @db_path_txt.text = @path
           # @db_path_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @db_path_btn = FXButton.new(db_frame, "add")
            @db_path_btn.connect(SEL_COMMAND){ 
              select_db_path
              # @db_path_txt.text = @path              
               }
            #@check_buttons = Hash.new
            
             
             path_index = 0
             @known_db_paths.each_with_index do |dbp,i|              
               if File.exist? dbp               
                   item = @db_path_combo.appendItem(dbp)
                   @db_path_combo.setItemData(item, dbp)
                   path_index = i if dbp == @path
               end
             end
             
             @db_path_combo.currentItem = path_index if @db_path_combo.numItems > 0
             
            @pbar = FXProgressBar.new(@settings_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)

            @speed = FXLabel.new(@settings_frame, "Requests per second: 0")

            @start_button = FXButton.new(@settings_frame, "start")
            @start_button.connect(SEL_COMMAND, method(:start))
            @start_button.disable

        #    gbox = FXGroupBox.new(@settings_frame, "Info", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 150)
        #    gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #    fxtext = FXText.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        #    fxtext.backColor = fxtext.parent.backColor
        #    fxtext.disable
        #    text = "Catalog-Scanner will test the web application for known directories and/or files. There must be two files in the appropriate plugin folder:\n"
        #    text << "- db_tests\n- db_variables\n\nThe format of these files is very similar to the format nikto (http://cirt.net/nikto2) is using. So if you have your own nikto.db-files, you"
        #    text << " can use them with this plugin."
        #    text << "\n\nCatalog Directory:\n#{File.dirname(__FILE__)}"
        #    fxtext.setText(text)

            @check = nil

            log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
            FXLabel.new(log_frame_header, "Logs:" )

            #log_text_frame = FXHorizontalFrame.new(bottom_frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_BOTTOM)
            log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            @log_viewer = LogViewer.new(log_text_frame, nil, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
       
            updateView()
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def create
          super                  # Create the windows
          @log_viewer.purge_logs
          @request_editor.setText('')
          @requestCombo.clearItems()

          @start_button.text = "Start"

          show(PLACEMENT_SCREEN) # Make the main window appear
          disableOptions()
          @start_button.disable
        end

     
        private
        

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
        #  puts "[#{self}] - createChat:"
        #  puts request
          chat = Watobo::Chat.new(request, [], :id => 0)
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
            @requestCombo.appendItem(text, chat)
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

        def onSiteSelect(sender, sel, item)
          ci = @sites_combo.currentItem
          @dir_combo.clearItems()
          @dir = ""
          @request_editor.setText('')
          @requestCombo.clearItems()

          if ci > 0 then
            @site = @sites_combo.getItemData(ci)
            if @site
              @dir_combo.appendItem("/", nil)

              chats = @project.findChats(@site, :method => "GET")
              updateRequestCombo(chats)
              updateRequestEditor(chats.first)
              if @project then
                @project.listDirs(@site) do |dir|
                  text = "/" + dir #.slice(0..35)
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

        def selectScanlogDirectory(sender, sel, item)
          workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Scanlog Directory", @scanlog_dir_dt.value)
          if workspace_dt != "" then
            if File.exists?(workspace_dt) then
              @scanlog_dir_dt.value = workspace_dt
              @scanlog_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
          end
        end
        
        def select_db_path(start_path = nil)
          s_path = start_path.nil? ? @path : start_path
          path = FXFileDialog.getOpenDirectory(self, "Select DB Path", s_path)
          unless path.empty?
            set_db_path(path)
          end
        end
        
        def set_db_path(path)
          if db_path?(path)
              puts "New DB Path >> #{path}"
                @path = path
          @known_db_paths << @path unless @known_db_paths.include? @path
          @start_button.enable
          unless @db_path_combo.findItemByData(@path)
            item = @db_path_combo.appendItem(dbp)
                   @db_path_combo.setItemData(item, @path)
                   @db_path_combo.currentItem = @db_path_combo.numItems - 1
            
          end
              
              save_config
            else
               @catalog_ready = false
              @start_button.disable
            end
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

          #  puts "* #{self.class} closed"
          @scanner.cancel() if @scanner

          self.destroy

        end
        
        def db_path?(path)
          @db_files.each do |file|
            fname = File.join( path, file)
            unless File.exists?(fname)
              puts "WARNING: Missing catalog db file: #{fname}"
              return false
            end
            
          end
        
          return true
        end
        
        def save_config()
        wd = Watobo.working_directory

        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "plugins")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_config.yml")
        config = { 
                   :db_path => @path,
                   :path_history => @known_db_paths                   
                   }
        Watobo::Utils.save_settings(file, config)
      end

      def load_config()
        wd = Watobo.working_directory
        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "plugins")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_config.yml")
        config = Watobo::Utils.load_settings(file)
      end

        def start(sender, sel, item)
          if @start_button.text =~ /cancel/i then
            @scanner.cancel()
            @start_button.text = "Start"
            @pbar.progress = 0
            return
          end

          if @logScanChats.checked?
            if @scanlog_dir_dt.value.empty?
              FXMessageBox.information(self,MBOX_OK,"Need Scan-Name", "Please provide a scan name!")
              return false
            end
          end          
          
          @start_button.text = "Cancel"


          @check = Check.new(@project)

          #@check.subscribe(:db_finished) {
          #    @pbar.increment(1)
          #puts @pbar.progress.to_s + "/" + @pbar.total.to_s
          #     if @pbar.progress == @pbar.total-1
          #       @pbar.barColor = 'grey'
          #       puts @pbar.progress.to_s + "/" + @pbar.total.to_s
          #     end

          #}

          @check.subscribe(:new_finding) { |f|
             @project.addFinding(f) 
          }

          @check.path = @path

          chatlist = []
          checklist = []
          checklist.push @check
          @check.resetCounters()

          @log_viewer.log( LOG_INFO, "Starting ...")
          puts "Site: #{@site}"
       #   progressWindow = Watobo::Gui::ProgressWindow.new(self, "Initialize Plugin")

        #  progressWindow.create
        #  progressWindow.show(PLACEMENT_SCREEN)
          #  progressWindow.newProject(@active_project, project_settings)

       #   progressWindow.register(self)
progressWindow = nil
  #        Thread.new(progressWindow){ |pw|
            begin
              c=1
              if @test_all_dirs.checked? then
                c = 0
                @project.listDirs(@site, :base_dir => @dir, :include_subdirs => @test_all_dirs.checked?) { c += 1 }
                notify(:update_progress, :total => c, :job => @dir)
                @project.listDirs(@site, :base_dir => @dir, :include_subdirs => @test_all_dirs.checked?) do |dir|
                  msg = "running checks on #{dir}"
                  puts msg
                  @log_viewer.log(LOG_INFO, msg)
                  chat = createChat()
                  chat.request.replaceFileExt('')
                  chat.request.setDir(dir)
                  chatlist.push chat
                  # @check.getCheckCount(chat)
                  @check.updateCounters(chat)
                 # pw.update_progress( :progress => 1)
                end
              else
            #    notify(:update_progress, :total => c, :job => @dir)
                msg = "running checks on #{@dir}"
                puts msg
                @log_viewer.log(LOG_INFO, msg)
                chat = createChat()
             #   puts chat.request.first
                chat.request.replaceFileExt('')
                chat.request.setDir(@dir)
              #  puts chat.request.first
                chatlist.push chat
                @check.updateCounters(chat)
             #   notify(:update_progress, :progress => 1)
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            ensure
            #  pw.hide
            end
 #         }

         # getApp().runModalWhileShown(progressWindow)

          scan_prefs = @project.getScanPreferences

          
          if @logScanChats.checked?
            scan_prefs[:scanlog_name] = @scanlog_dir_dt.value unless @scanlog_dir_dt.value.empty?
          end
          

          @scanner = Watobo::Scanner2.new(chatlist, checklist, @project.passive_checks, scan_prefs)
          @pbar.total = @check.numChecks * chatlist.length
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

          msg= "Total Requests: #{@check.numChecks}"
          @log_viewer.log(LOG_INFO, msg)
         

        st =  Thread.new(@scanner){ |scan| 
            begin
              msg = "start scanning..."
              @log_viewer.log(LOG_INFO, msg)
             
              scan.run(:run_passive_checks => false)
              
              msg = "scanning finished!"
              @log_viewer.log(LOG_INFO, msg)
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
            @pbar.progress = 0
            @pbar.barColor = 'grey'
            @speed.text = "Requests per second: 0"
            @start_button.text = "Start"
          }
       #   st.join
        end

      end
    end
  end
end

if __FILE__ == $0
  puts "Running #{__FILE__}"
  catalog = Watobo::Plugin::Catalog.new(project)
end
