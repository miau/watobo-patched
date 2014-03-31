# .
# gui.rb
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
        
        
      class Main < Watobo::Plugin2

        include Watobo::Constants
        
        def createChat(site)
          chat = nil
          url = "https://#{site}/"
          request = []
          request << "GET #{url} HTTP/1.1\r\n"
          request << "Host: #{site}\r\n"
          request << "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*\r\n"
          request << "Accept-Language: de\r\n"
          request << "Proxy-Connection: close\r\n"
          request << "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)\r\n"
          request << "\r\n"

          chat = Watobo::Chat.new(request, [], :id => 0)

          return chat
        end

        def onSiteSelect(sender, sel, item)
          if sender.numItems > 0
          @site = sender.getItemData(sender.currentItem)
          else
            unless sender.text.empty?
            @site = sender.text.gsub(/^https?:\/\//,"").strip 
            end
          end
         
        end

        def updateView()
          #@project = project
          @site = nil
          @sites_combo.clearItems()
          #@dir_combo.clearItems()
          unless @project.nil? then
            @project.listSites(:ssl => true).each do |site|
            #puts "Site: #{site}"
              @sites_combo.appendItem(site.slice(0..35), site)
            end
            if @sites_combo.numItems > 0
            @sites_combo.setCurrentItem(0)
            @site = @sites_combo.getItemData(0)
            else
            @log_viewer.log(LOG_INFO,"No SSL Sites available - you need to visit a SSL Site first!")
            end
          end

        end

        def start(sender, sel, item)
          unless @site.nil?
   @cipher_table.clear_ciphers

            #puts "Site: #{site}"
            #puts "Directory: #{@dir}"
            chat = createChat(@site)
            checklist = []
            checklist.push @check
            chatlist = []
            chatlist.push chat
            scan_prefs = @project.getScanPreferences
            scanner = Watobo::Scanner2.new(chatlist, checklist, nil, scan_prefs)

             @pbar.total = scanner.numTotalChecks
               #@pbar.progress = 0
               #@pbar.barColor = FXRGB(255,0,0)

               scanner.subscribe(:progress) { |m|
                           print "="
                  @pbar.increment(1)
               }
            
            #@pbar.total = @check.cipherlist.length
            @pbar.progress = 0
            @pbar.barColor = 'red'
            unless @project.getCurrentProxy().nil?
               @log_viewer.log(LOG_INFO,"!!! WARNING FORWARDING PROXY IS SET !!! - SSL-Check running against proxy may not make sense!")
            end
            @log_viewer.log LOG_INFO, "Scan started ..."
            @scan_thread = Thread.new(scanner) { |scan|
              begin

                scan.run(:default => true)
                @log_viewer.log LOG_INFO, "Scan finished."
              rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              end
            }

          end
        end

        def initialize(owner, project)
          super(owner, "SSL-Plugin", project, :opts => DECOR_ALL,:width=>800, :height=>600)

          @plugin_name = "SSL-Checker"
          @project = project
          @site = nil
          @dir = nil
          @scan_thread = nil
          
          @results = []
          @results_lock = Mutex.new
          
           @clipboard_text = ""
        self.connect(SEL_CLIPBOARD_REQUEST) do
        # setDNDData(FROM_CLIPBOARD, FXWindow.stringType, Fox.fxencodeStringData(@clipboard_text))
          setDNDData(FROM_CLIPBOARD, FXWindow.stringType, @clipboard_text + "\x00" )
        end
          
          load_icon(__FILE__)

          mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
          # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
          top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM,:height => 500)
          top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
          log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)

          @settings_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_Y)
          result_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          
          @controller = CipherTableController.new(result_frame, :opts => LAYOUT_FILL_X)
          @controller.subscribe(:apply_filter){ |f| @cipher_table.filter = f ; @cipher_table.update_table}
          @controller.subscribe(:copy_table){
             types = [ FXWindow.stringType ]
                    if acquireClipboard(types)
                    puts
                    @clipboard_text = @cipher_table.to_csv
                    end

          }

         frame = FXVerticalFrame.new(result_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
         @cipher_table = CipherTable.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

          FXLabel.new(@settings_frame, "Available Sites:")
          @sites_combo = FXComboBox.new(@settings_frame, 5, nil, 0,
          COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          #@filterCombo.width =200

          @sites_combo.numVisible = 20
          @sites_combo.numColumns = 35
          @sites_combo.editable = true
          @sites_combo.connect(SEL_COMMAND, method(:onSiteSelect))
          begin

       
            @pbar = FXProgressBar.new(@settings_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
            
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)

            button = FXButton.new(@settings_frame, "start")
            button.connect(SEL_COMMAND, method(:start))

            @check = Check.new(@project)

            @check.subscribe(:cipher_checked) { |cipher, bits, result|
              begin
                @results_lock.synchronize do
                @results << { :name => cipher, :bits => bits, :result => result}
                end
               #  FXApp.instance.forceRefresh
              rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              end
            #puts "#{@pbar.progress} of #{@pbar.total}"
            #     logger

            }

            @check.subscribe(:new_finding) { |f|
              @project.addFinding(f)
            }

            log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
            FXLabel.new(log_frame_header, "Logs:" )

            #log_text_frame = FXHorizontalFrame.new(bottom_frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_BOTTOM)
            log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            updateView()
            add_update_timer(50)
          rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          end

        end
        
        private
        
        def add_update_timer(ms)
         @update_timer = FXApp.instance.addTimeout( ms, :repeat => true) do
          @results_lock.synchronize do
          unless @results.empty?
            @results.each do |r|
            @cipher_table.add_cipher(r)
          end
        @results.clear
        end
    end
    
  end
end
      end
      end
      end
      end
      end