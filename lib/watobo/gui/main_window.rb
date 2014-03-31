# .
# main_window.rb
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
    ####################################################################################################################
    # M A I N   A P P L I C A T I O N   W I N D O W
    #
    class MainWindow < FXMainWindow
      
      include Watobo
      include Watobo::Gui
      include Watobo::Constants
      include Watobo::Gui::Icons

      attr :interceptor
      attr :default_settings
      attr :watobo_base
      attr :active_project
      attr :iproxy
      
      def open_manual_request_editor(chat)
        begin
          mrtk = ManualRequestEditor.new(FXApp.instance, @active_project, chat)

          mrtk.create

          mrtk.subscribe(:show_browser_preview) { |request, response|
            openBrowser(request, response)
          }

          mrtk.subscribe(:new_chat) { |c|
            @active_project.addChat(c)
          }
          mrtk.show(Fox::PLACEMENT_SCREEN)
        rescue => bang
        puts "!!! could not open manual request"
        puts bang
        end
      end

      private

 def add_queue_timer(ms)
  @update_timer = FXApp.instance.addTimeout( ms, :repeat => true) {
    @finding_lock.synchronize do
      @finding_queue.each do |f|
        addFinding(f)
      end
      @finding_queue.clear
    end
    
    @chat_lock.synchronize do
      @chat_queue.each do |c|
        addChat(c)
      end
      @chat_queue.clear
    end
    
    @status_lock.synchronize do
      
    end
    
  }
 end

      
      #def loadDefaultS
      def saveDefaultSettings_UNUSED(update_settings={})

=begin
        settings= Hash.new
        [:password_policy, :history, :interceptor, :forwarding_proxy].each do |k|
        settings[k] = @settings[k]
        settings[k] = update_settings[k] if update_settings.has_key?(k)
        end
        # clean up few settings
        settings[:forwarding_proxy].delete :name

        settings[:general] = {
        :working_directory => @settings[:general][:working_directory],
        :workspace_path => @settings[:general][:workspace_path]
        }
        #  puts YAML.dump(settings[:forwarding_proxy])
        # check for proxy credentials
        proxy_has_credentials = false

        settings[:forwarding_proxy].each_key do |p|
        next if p == :default_proxy
        proxy = settings[:forwarding_proxy][p]

        if proxy.has_key? :credentials
        unless proxy[:password] == ''
        #       puts " - proxy #{p} has password #{proxy_list[p][:credentials][:password]}"
        proxy_has_credentials = true
        end
        end
        end

        if proxy_has_credentials == true
        if @settings[:password_policy][:save_passwords] == true
        if @settings[:password_policy][:save_without_master] == false
        if @settings[:master_password].empty?
        puts "* need master password for proxy"
        dlg = MasterPWDialog.new(self)
        if dlg.execute != 0
        @settings[:master_password] = dlg.masterPassword
        end
        end
        unless @settings[:master_password].empty?
        settings[:forwarding_proxy].each_key do |p|
        #creds = settings[:forwarding_proxy][p][:credentials]
        #pass = "$$WPE$$" + creds[:password]
        pass = settings[:forwarding_proxy][p][:password]
        unless pass.empty?
        creds[:password] = Crypto.encryptPassword(pass, @settings[:master_password])
        creds[:encrypted] = true
        end
        end
        else
        cleanCredentials(settings)
        FXMessageBox.information(self,MBOX_OK,"No MasterPassword", "Could not encrypt proxy passwords. No Passwords have been saved!")
        end
        else
        puts "* saving passwords without protection!!!!"
        end
        else
        cleanCredentials(settings)
        end
        end

        # puts "=== DEFAULT SETTINGS PASSWORD POLICY"
        # puts YAML.dump(settings)
        Watobo::Utils.save_settings(@default_settings_file, settings )
=end
      end

      def saveSessionSettings(project=nil)
        return
        puts "- saveSessionSettings -"
        ss = YAML.load(YAML.dump(project.settings))
        unless project.nil?
          puts "* saving session settings to #{project.sessionSettingsFile}"
          settings = Hash.new
          [:logout_signatures, :non_unique_parms, :login_chat_ids, :excluded_chats, :project_name, :session_name, :csrf_request_ids ].each do |k|
            settings[k] = Hash.new
            settings[k] = ss[k] if ss.has_key?(k)
          end

        Watobo::Utils.save_settings(project.sessionSettingsFile, settings)
        end
      end

      def saveProjectSettings(project=nil)
        return
        unless project.nil?
          ps = YAML.load(YAML.dump(project.scan_settings))
          settings = { :scanner => Hash.new }
          [:policy, :scope, :www_auth ].each do |k|
            settings[:scanner][k] = Hash.new
            settings[:scanner][k].update ps[k] if ps.has_key?(k)
          end

          settings[:scanner][:custom_error_patterns] = ps[:custom_error_patterns]
          settings[:scanner][:csrf_patterns] = ps[:csrf_patterns] unless ps[:csrf_patterns].nil?

          # remove proxy list because they are stored in the default settings
          settings[:forwarding_proxy] = project.forward_proxy_settings

          settings[:project_name] = project.project_name
          #   puts "==== WWW AUTH ==="
          #   puts YAML.dump( settings[:www_auth] )

          #     puts "=== PASSWORD POLICY ==="
          #     puts YAML.dump(@settings[:password_policy])
          #if master_password_required?
          password_set = false
          settings[:www_auth].each_key do |p|
            if settings[:www_auth][p].has_key? :password
            password_set = true unless settings[:www_auth][p][:password] == ''
            end
          end
          if @settings[:password_policy][:save_passwords] == true
            unless settings[:www_auth].empty?
              if @settings[:password_policy][:save_without_master] == false
                if password_set and @settings[:master_password].empty?
                  puts "* need master password for server auth encryption"
                  dlg = MasterPWDialog.new(self)
                  if dlg.execute != 0
                  @settings[:master_password] = dlg.masterPassword
                  end
                end
                unless @settings[:master_password].empty?
                  settings[:www_auth].each_key do |p|
                    creds = settings[:www_auth][p]
                    #pass = "$$WPE$$" + creds[:password]
                    pass = creds[:password]
                    if pass != ''
                    creds[:password] = Crypto.encryptPassword(pass, @settings[:master_password])
                    creds[:encrypted] = true
                    end
                  end
                else
                cleanCredentials(settings)
                FXMessageBox.information(self,MBOX_OK,"No MasterPassword", "Could not encrypt www_auth passwords. No Passwords have been saved!")
                end

              else
              puts "* saving passwords without protection!!!!"
              end
            end
          else
          cleanCredentials(settings)
          end

        #   puts "* saving www_auth settings ..."
        #   puts YAML.dump( settings[:www_auth])
        Watobo::Utils.save_settings(project.projectSettingsFile, settings)
        end
      end

      def update_conversation_table(project)
         @chatTable.showConversation(project.chats)
         @chatTable.apply_filter()  
      end
      
      #
      # SHOW CHAT
      #
      def showChat(chat)
        @last_chat = chat
        @mre_button.enabled = true
        @fuzz_button.enabled = true
        @bv_button.enabled = true

        @request_viewer.setText(chat.request)
        @last_request = chat.request
        @response_viewer.setText(chat.response)
        @last_response = chat.response
        @switcher.current=0
        @lastViewed = chat
        src = case chat.source
        when CHAT_SOURCE_INTERCEPT
          "Interceptor"
        when CHAT_SOURCE_PROXY
          "Proxy"
        when CHAT_SOURCE_MANUAL
          "Manual"
        when CHAT_SOURCE_FUZZER
          "Fuzzer"
        end
        @quickViewTitle.text = "Chat-ID: #{chat.id} (#{src})"
        @quickViewSubTitle.text = ""
      end

      #
      # SHOW VULN
      #
      def showVulnerability(vuln)
        @mre_button.enabled = true
        @fuzz_button.enabled = true
        @bv_button.enabled = true

        @chatTable.killSelection()
        @request_viewer.setText(vuln.request)
        @last_request = vuln.request
        @response_viewer.setText(vuln.response)
        @last_response = vuln.response

        @lastViewed = vuln
        if vuln.details[:check_pattern] then

        pattern = vuln.details[:check_pattern].strip

        @request_viewer.highlight(pattern)
        end

        if vuln.details[:proof_pattern] then
        pattern = vuln.details[:proof_pattern].strip
        @response_viewer.highlight(pattern)
        end
        @switcher.current = 0

        @quickViewTitle.text = "Finding: #{vuln.details[:class]}"
        chat_id = "unknown"
        chat_id = vuln.details[:chat_id] if vuln.details.has_key? :chat_id
        info_text = "[Module: #{vuln.details[:module].gsub(/watobo::modules::/i,'')}] [Chat-ID: #{chat_id}]"
        @quickViewSubTitle.text = info_text

      end

      def addFinding(finding)
        @findings_tree.addFinding(finding)
      end

      def openSessionManagement(sender, sel, item)
        smdlg = SessionManagementDialog.new(self, @active_project)
        if smdlg.execute != 0 then
          ids = smdlg.getLoginScriptIds()
          sidpatterns = smdlg.getSidPatterns()
          logout_signatures = smdlg.getLogoutSignatures()
          if @active_project
          @active_project.setLoginChatIds(ids)
          @active_project.setSidPatterns(sidpatterns)
          @active_project.setLogoutSignatures(logout_signatures)
          end
        # save settings
        saveProjectSettings(@active_project)
        saveSessionSettings(@active_project)
        end
      end

      def openPreferencesDialog(sender, sel, ptr)
=begin
        prefdlg = PreferencesDialog.new(self, @settings)
        if prefdlg.execute != 0
        ip = @settings[:interceptor]
        if ip[:intercept_port] != prefdlg.settings[:intercept_port] then
        FXMessageBox.information(self,MBOX_OK,"Intercept Port Changed", "Please restart WATOBO!")
        end
        @settings.update(prefdlg.settings)
        puts prefdlg.settings

        update_status_bar()
        if @active_project then
        @active_project.settings.update(@settings)
        @active_project.saveProjectSettings()
        end

        end
=end
      end

      def openCADialog(sender, sel, item)
        cadlg = CertificateDialog.new(self, @active_project)
        if cadlg.execute != 0

        end
      end

      def openWwwAuthDialog()
        if @active_project.nil?
        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First")
        else
          auth_settings = {}
          w3adlg = Watobo::Gui::WwwAuthDialog.new(self, @active_project, Watobo::Conf::General.dump )
          if w3adlg.execute != 0
          #puts "* New WWW-Authentication"
          #puts @active_project.getWwwAuthentication().to_yaml
          Watobo::Conf::General.save_passwords = w3adlg.savePasswords?
          saveProjectSettings(@active_project)
          Watobo::Gui.save_default_settings(@active_project)
          @iproxy.www_auth = @active_project.getWwwAuthentication()
          end
        puts "* new www_auth settings"
        # puts YAML.dump(@active_project.settings[:www_auth])
        end

      end

      def open_client_cert_dialog()
        if @active_project.nil?
        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First")
        else
          ccdlg = Watobo::Gui::ClientCertDialog.new(self, @active_project )
          if ccdlg.execute != 0
          #puts "* New WWW-Authentication"
          #puts @active_project.getWwwAuthentication().to_yaml
          @settings[:password_policy][:save_passwords] = ccdlg.savePasswords?
          puts "* got client certificate settings"
          puts ccdlg.client_certificates.to_yaml
          @active_project.client_certificates = ccdlg.client_certificates
          @iproxy.client_certificates = ccdlg.client_certificates
          saveProjectSettings(@active_project)
          # Watobo::Gui.save_default_settings(@active_project)

          end
        # puts YAML.dump(@active_project.settings[:www_auth])
        end

      end

      def openPWPolicyDialog()
        if @active_project.nil?
        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First")
        else
          auth_settings = {}
          dlg = Watobo::Gui::PasswordPolicyDialog.new(self, @settings[:password_policy] )
          if dlg.execute != 0
          @settings[:password_policy] = dlg.passwordPolicy
          Watobo::Gui.save_default_settings(@active_project)
          #puts "* New WWW-Authentication"
          #puts @active_project.getWwwAuthentication().to_yaml
          #@settings[:password_policy][:save_passwords] = w3adlg.savePasswords?
          saveProjectSettings(@active_project)
          #@iproxy.www_auth = @active_project.settings[:www_auth]
          end
        end

      end

      def openFuzzer(chat)
        begin
          fuzzer = FuzzerGui.new(FXApp.instance, @active_project, chat)
          fuzzer.create
          fuzzer.show(Fox::PLACEMENT_SCREEN)
        rescue => bang
        puts "!!! could not open fuzzer"
        puts bang
        end
      end

      def addChat(chat)
        # addChatToTable(chat) if chatIsFiltered?(chat) == false
        @chatTable.addChat(chat) #if chatIsFiltered?(chat) == false
        @sites_tree.addChat(chat)
      end

      def showPassiveCheckStatus
        @switcher.current=2
        @dashboard.tabBook.current = 1
      end

      def showActiveCheckStatus
        @switcher.current=2
        @dashboard.tabBook.current = 2
      end

      def showDashboard(sender, sel, ptr)
        #@switcher.current=2
        begin
          @switcher.setCurrent(2, true)
        rescue
        puts "no dashboard available yet!"
        end
      end

      def showLogs(sender, sel, ptr)
        @switcher.current=1
      end

      def showConversation(sender=nil, sel=nil, item=nil)
        @switcher.current=0
      end

      def openBrowser(request, response)
        begin
          @browserView.show(request, response)
        rescue => bang
          puts "!!! PREVIEW PROBLEM !!"
          puts bang
          case bang
          when /JSSH_CONNECT_ERROR/i
            FXMessageBox.information(self, MBOX_OK, "JSSH Missing", "It seem that the Firefox JSSH extension is not installed,\nwhich is required in order to use the BrowserPreview.\nPlease read the installation instruction in the README\n or online at http://watobo.sourceforge.net.")
          else
          FXMessageBox.information(self, MBOX_OK, "Proxy Settings", "Your Browser does not use WATOBO (127.0.0.1:#{@iproxy.port}) as its proxy.\nSo you can't use the Browser-View feature.\nPlease change your proxy settings and try it again!")
          end
        end
      end

      def update_history(project)
        # @settings[:history].unshift session_file if not @settings[:history].include?(session_file)
        # @settings[:history].pop if @settings[:history].length > 5
      end

      def updateTreeLists()
        @findings_tree.refresh_tree()
        @sites_tree.refresh_tree()
      end

      def openTranscoder(text2transcode)
        transcoder = TranscoderWindow.new(FXApp.instance, text2transcode)
        transcoder.create
        transcoder.show(Fox::PLACEMENT_SCREEN)
      end

      def showFindingDetails(finding)
        #p "* show finding details"
        @finding_info.showInfo(finding)
        @switcher.setCurrent(3, true)
      end

      def onShowPlugins(sender, sel, item)
        begin
          @switcher.setCurrent(4, true)
          @pluginboard.updateBoard()
        rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        end
      end

      def useSmallIcons()
        unless @active_project.nil?
        @findings_tree.useSmallIcons()
        @sites_tree.useSmallIcons()
        # @chatTable.setNewFont( "helvetica", GUI_SMALL_FONT_SIZE)
        @chatTable.setNewFont("Segoe UI", GUI_SMALL_FONT_SIZE)
        @request_viewer.setFontSize(GUI_SMALL_FONT_SIZE)
        @response_viewer.setFontSize(GUI_SMALL_FONT_SIZE)
        else
        end
      end

      def useRegularIcons()
        unless @active_project.nil?
        @findings_tree.useRegularIcons()
        @sites_tree.useRegularIcons()
        @chatTable.setNewFont("Segoe UI", GUI_REGULAR_FONT_SIZE)
        #@chatTable.setNewFont("helvetica", GUI_REGULAR_FONT_SIZE)
        @request_viewer.setFontSize(GUI_REGULAR_FONT_SIZE)
        @response_viewer.setFontSize(GUI_REGULAR_FONT_SIZE)
        else
        end
      end

      def onOpenTranscoder(sender, sel, item)

        openTranscoder(nil)

      end

      def refreshViewers()
        @findings_tree.refresh_tree()
        @sites_tree.refresh_tree()
      #@chatTable.clearItems()
      end

      def onOpenInterceptor(sender, sel, ptr)
        if @active_project then
        interceptor = Watobo::Gui::InterceptorUI.new(self, @iproxy, :opts => DECOR_ALL)
        iproxy.target = interceptor
        puts "* Interceptor created"
        #@active_project.interceptor = interceptor
        interceptor.create
        interceptor.show(Fox::PLACEMENT_SCREEN)
        getApp().runModalWhileShown(interceptor)
        interceptor.releaseAll()
        puts "* Interceptor closed"
        iproxy.target = nil
        #if interceptor.execute != 0 then
        #  puts "interceptor finished"
        #end
        else

        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First")
        end
      end

      def update_status_bar(project)
        @statusBar.projectName = project.projectName
        @statusBar.sessionName = project.sessionName
        @statusBar.portNumber = Watobo::Conf::Interceptor.port.to_s
        @statusBar.forwardingProxy = "-"
        proxy = project.getCurrentProxy()
        unless proxy.nil?
        @statusBar.forwardingProxy = "#{proxy[:name]} (#{proxy[:host]}:#{proxy[:port]})"
        end
        @statusBar.statusInfoText = "Ready"
        @scan_button.enable
        @dashboard.updateProjectInfo(project)
      end

      def setupProgressWindow(title, numTotal)
        @progressWindow = Watobo::Gui::ProgressWindow.new(self, title, numTotal)

        @progressWindow.create
        @progressWindow.show(PLACEMENT_SCREEN)
        #  getApp().runModalWhileShown(@progressWindow)
        return @progressWindow

      end

      def closeProgressWindow
        # getApp().stopModal()
        @progressWindow.finished
      end

      def disableFileMenu
        @file_new_menu.enabled = false
        @file_history.disable
        @new_project_button.disable
      end



      def closeProject()
        @active_project = nil
        @findings_tree.clearItems()
        @sites_tree.clearItems()
        @chatTable.clearItems()
        @request_viewer.setText('')
        @response_viewer.setText('')
        @lastViewed = nil
        @last_request = nil
        @last_response = nil
        @iproxy.stop if @iproxy

      end

      #
      # onNewProject
      #
      def onNewProject(sender,sel,ptr)

        if @active_project then
        response = FXMessageBox.question(self, MBOX_YES_NO, "New Project", "This will close the actual project!\nAre you sure?")
        return 0 if not response == MBOX_CLICKED_YES
        # clear old project
        closeProject()
        # stop interceptor
        end

        puts "* Open Project Wizzard (#{Watobo::Conf::General.workspace_path})" if $DEBUG
        newProjectWizzard = Watobo::Gui::NewProjectWizzard.new(self, Watobo::Conf::General.workspace_path )
        if newProjectWizzard.execute != 0
          # prepare project settings
          new_project_settings = {
            :project_path => newProjectWizzard.selected_project_path,
            :session_path => newProjectWizzard.selected_session_path,
            :project_name => newProjectWizzard.project_name,
            :session_name => newProjectWizzard.session_name
          }
        #  @settings[:general][:workspace_path] = newProjectWizzard.workspace_dir
        Watobo.workspace_path = newProjectWizzard.workspace_dir

        project = Watobo.create_project(:project_name => newProjectWizzard.project_name, :session_name => newProjectWizzard.session_name)
        
        startProject(project)
               
        Watobo::Gui.history.add_entry(:project_name => new_project_settings[:project_name], :session_name => new_project_settings[:session_name])
        Watobo::Gui.save_default_settings project
        puts Watobo::Gui.active_project.class
        end

      end

      def startProject(project)

        return false unless project.is_a? Project

        puts "DEBUG: starting project" if $DEBUG
        @active_project = project

        subscribeProject(@active_project)

        @active_project.subscribe(:update_progress){ |up|
          begin
            @progress_window.update_progress(up)
          rescue => bang
          puts bang
          end
        }

        @progress_window.title = "Start Project"
        @progress_window.show(PLACEMENT_OWNER)
        @chatTable.hide
        @sites_tree.hide
        @findings_tree.hide
        #TODO: Disable Menu

        Thread.new{
          begin
            print "\n* setting up project ..."
            @active_project.setupProject()
            print "[OK]\n"

            #puts "= SETTINGS ="
            #puts @settings.to_yaml
            @iproxy = Watobo::InterceptProxy.new()
            @iproxy.subscribe(:new_interception) { |chat|
              Thread.new(chat) { |c|
                @active_project.addChat(c)
              }
            }
            @iproxy.run()
            puts "DEBUG: Proxy running" if $DEBUG
            #   puts "* set www_auth for interceptor"
            #   puts YAML.dump(@active_project.settings[:www_auth])
            @iproxy.www_auth = @active_project.settings[:www_auth]

            @browserView = BrowserPreview.new(@iproxy)

           
            Watobo::Gui.clear_plugins
            Watobo::Gui::Utils.load_plugins(@active_project)
            #            saveProjectSettings(@active_project)
            #            saveSessionSettings(@active_project)

            @sites_tree.project = @active_project
            @findings_tree.project = @active_project
            Watobo::Gui.active_project = @active_project
            puts "* finished, closing progress window" if $DEBUG

          rescue => bang
          # puts "!!! Could not create project"
            puts bang
            puts bang.backtrace if $DEBUG
            puts "!!! Could not create project :("
          ensure
          puts "* stop modal mode" if $DEBUG
          getApp.stopModal

          end

        }
        getApp().runModal
      #  puts "* finished modal mode"
       update_conversation_table(@active_project)

            update_status_bar(@active_project)
        @progress_window.hide
        @chatTable.show
        @sites_tree.show
        @findings_tree.show
      end

      def decryptPassword(enc_pw=nil, dlg_titel="Encrypted Password")
        bad_pass_count = 0
        dlg_canceled = false
        dec_pw = nil
        while bad_pass_count < 3 and dlg_canceled == false and dec_pw.nil?
          if @settings[:master_password].empty?
            note = ""
            message = case bad_pass_count
            when 1
              "Bad Password!!!\n"
            when 2
              "Wrong Password Again? Next time WATOBO will continue without loading stored passwords.\n"
            else
            "Please provide the master-password to decrypt passwords.\n"
            end
            message << "If you hit 'cancel' the passwords will be deleted!\nYou can disable master-password in the settings menu.\nThe latter is not recommended!"
            dlg = MasterPWDialog.new(self, dlg_titel, :info => message, :retype => false)
            if dlg.execute != 0
              master_pass = dlg.master_password
              begin
                dec_pw = Crypto.decryptPassword(enc_pw, master_pass)
                @settings[:master_password] = master_pass
              rescue => bang
              puts "! wrong password"
              @settings[:master_password] = ''
              bad_pass_count += 1
              #FXMessageBox.information(self,MBOX_OK,"Wrong Password!", "Could not decrypt proxy passwords. Check proxy settings!")
              end
            else
            dlg_canceled = true
            @settings[:master_password] = ''
            end
          else
            begin
              dec_pw = Crypto.decryptPassword(enc_pw, @settings[:master_password])
              #  @settings[:master_password] = master_pass
            rescue => bang
            @settings[:master_password] = ''
            #FXMessageBox.information(self,MBOX_OK,"Wrong Password!", "Could not decrypt proxy passwords. Check proxy settings!")
            end
          end
        end
        dec_pw
      end

      def decryptCredentials(settings)
        # now check credentials
        decrypt_failed = false

        #    puts "=== Check Credentials ==="
        if settings.has_key? :forwarding_proxy

          settings[:forwarding_proxy].each_key do |k|
            next if k == :default_proxy
            proxy = settings[:forwarding_proxy][k]
            proxy[:password] = '' unless proxy.has_key? :password
            proxy[:encrypted] = false unless proxy.has_key? :encrypted
            if proxy[:password] != '' and proxy[:encrypted] == true
              unless decrypt_failed
                #  puts "* decrypting password for proxy #{proxies[k][:host]}"
                dp = decryptPassword(proxy[:password], "Decrypt Proxy Passwords")
                unless dp.nil?
                proxy[:password] = dp
                proxy[:encrypted] = false
                else
                proxy[:password] = ''
                proxy[:encrypted] = false
                decrypt_failed = true
                FXMessageBox.information(self,MBOX_OK,"Wrong Master Password!", "Could not decrypt passwords. Please reconfigure proxy passwords!")
                end
              else
              proxy[:password] = ''
              proxy[:encrypted] = false
              end
            end
          end
        end

        unless settings[:www_auth].nil?

          settings[:www_auth].each_key do |wa|

            if settings[:www_auth][wa][:encrypted] == true
              creds = settings[:www_auth][wa]
              unless decrypt_failed
                dp = decryptPassword(creds[:password], "Decrypt Server Password")
                unless dp.nil?
                creds[:password] = dp
                creds[:encrypted] = false
                else
                creds[:password] = ''
                creds[:encrypted] = false
                decrypt_failed = true
                FXMessageBox.information(self,MBOX_OK,"Wrong Master Password!", "Could not decrypt passwords. Please reconfigure server passwords!")
                end
              else
              creds[:password] = ''
              creds[:encrypted] = false
              end

            end
          end
        end

      end

      def openSession( prefs = {} )
#        puts "= Loading Session ="
#        session_file = File.join( Watobo.workspace_path, prefs[:project_name], prefs[:session_name] )
#        puts "SessionFile: #{session_file}"
        if @active_project then
        response = FXMessageBox.question(self, MBOX_YES_NO, "New Project", "This will close the actual project!\nAre you sure?")
        return false if not response == MBOX_CLICKED_YES
        # clear old project
        closeProject()
        # stop interceptor
        end

        session_settings = {}

#        if File.exists?(session_file) then
#        session_settings = Watobo::Utils.loadSettings(session_file)
        #updateistory(session_file)

#        else
#        puts "!!! Session file does not exist (#{session_file})."
#        return false
#        end

        return false unless prefs.has_key? :project_name
        return false unless prefs.has_key? :session_name

        project = Watobo.create_project(
        :project_name => prefs[:project_name],
        :session_name => prefs[:session_name]
        )

        puts "* starting project"
        startProject(project)
=begin
      project_file = File.expand_path(File.join(File.dirname(session_file), "..", session_settings[:project_name] + ".wps"))
      if File.exists?(project_file) then
      project_settings = Watobo::Utils.loadSettings(project_file)
      if not project_settings.is_a? Hash then
      project_settings = Hash.new
      end
      new_project_settings = Hash.new
      new_project_settings.update(@settings)
      new_project_settings.update(project_settings)
      new_project_settings.update(session_settings)
      new_project_settings[:workspace_path] = File.join(File.dirname(project_file), "..")

      # need to restore forwarding proxy list
      #          new_project_settings[:forwarding_proxy] = @forward_proxy_settings

      decryptCredentials(new_project_settings)
      #  puts "* project settings"
      # puts new_project_settings[:www_auth].to_yaml
      project = Watobo::Project.new(new_project_settings)

      if project
      @projects[project] = {
      :session_file => session_file,
      :project_file => project_file
      }
      startProject(project)
      Watobo::Gui.save_default_settings(@active_project)
      end

      return true
      else
      puts "!!! No project file available (#{project_file})."
      return false
      end
=end
      end

      def setActiveProject(project)
        @active_project = project
      end

      def openScannerSettingsDialog(sender,sel,ptr)
        if @active_project then
          settings = @active_project.getScanPreferences()
          # puts settings.to_yaml
          dlg = Watobo::Gui::ScannerSettingsDialog.new(self, settings, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          if dlg.execute != 0 then
          # puts dlg.scanner_settings.to_yaml
          @active_project.updateSettings(YAML.load(YAML.dump(dlg.scanner_settings)))
          saveProjectSettings(@active_project)

          end
        else
        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First!")
        end
      end

      def openInterceptorSettingsDialog(sender,sel,ptr)
        dlg = Watobo::Gui::InterceptorSettingsDialog.new(self)
        if dlg.execute != 0 then
        puts dlg.interceptor_settings.to_yaml
        Watobo::Conf::Interceptor.set dlg.interceptor_settings 
        #@settings[:interceptor].update YAML.load(YAML.dump(dlg.interceptor_settings))
        #@active_project.updateSettings(YAML.load(YAML.dump(dlg.scanner_settings)))
        FXMessageBox.information(self, MBOX_OK, "Restart required!", "You must restart WATOBO in order your changes take effect.")
        Watobo::Conf::Interceptor.save
        #Watobo::Gui.save_default_settings(@settings[:interceptor])
        end
      end

      def openScopeDialog(sender,sel,ptr)
        dlg = Watobo::Gui::EditScopeDialog.new(self, @active_project, LAYOUT_FILL_X|LAYOUT_FILL_Y)
        if dlg.execute != 0 then
        @active_project.scope = YAML.load(YAML.dump(dlg.scope))
        saveProjectSettings(@active_project)
        refreshViewers()
        end
      end

      def startFullScan(sender,sel,ptr)
        if @scan_button.icon == ICON_STOP
        @scanner.cancel() if @scanner
        @scan_button.icon = ICON_START
        @scan_running = false
        else
          dlg = Watobo::Gui::FullScanDialog.new(self, @active_project, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          if dlg.execute != 0 then

            @scan_running = true
            @scan_button.icon = ICON_STOP
            #@pause_scan_button.enable
            @active_project.setScope(dlg.scope)

            #  saveProjectSettings(@active_project)
            #  saveSessionSettings(@active_project)

            #@active_project.scanLogDirectory = dlg.scan_prefs[:scanlog_dir] unless dlg.scan_prefs[:scanlog_dir] == ''

            #   chats = @active_project.getChats(dlg.scope)
            dlg_modules = dlg.activeModules().map{ |m| m.class.to_s}
            # we only need array of selected class names
            #  scan_modules = dlg.selectedModules().map{ |m| m.class.to_s }
            acc = @active_project.active_checks.select do |ac|
              dlg_modules.include? ac.class.to_s
            end

            in_scope_chats = @active_project.chatsInScope()
            #  puts "Chats to scan:"
            #  puts in_scope_chats.length
            #  p

            confirm_dlg = Watobo::Gui::ConfirmScanDialog.new(self, in_scope_chats, @active_project.getScanPreferences())
            if confirm_dlg.execute == 0
            @scan_button.icon = ICON_START
            @scan_running = false
            return 0
            end

            scan_prefs = @active_project.getScanPreferences()
=begin
            scan_prefs[:scanlog_dir] = dlg.scan_prefs[:scanlog_dir]
            if File.exist?(scan_prefs[:scanlog_dir]) then
            new_dir = File.join(scan_prefs[:scanlog_dir], "scan-" + Time.now.to_f.to_s + "_full")
            Dir.mkdir(new_dir)
            scan_prefs[:scanlog_dir] = new_dir
            end
=end

            #scan_prefs[:data_store] = @active_project.datastore
            scan_prefs[:scan_name] = "scan_" + Time.now.to_i.to_s + "_full"

            @scanner = Watobo::Scanner2.new(in_scope_chats, acc , @active_project.passive_checks, scan_prefs)

            @scanner.subscribe(:progress) { |check|
                  @dashboard.progress(check)
            
            }

            @scanner.subscribe(:module_finished) { |mod|
              
                  @dashboard.module_finished(mod)
                
            }

            @scanner.subscribe(:logger){ |level, message|
             
               @log_viewer.log(level, message)
              
            }


            @scanner.subscribe(:new_finding) { |finding|
              begin
                @active_project.addFinding(finding)
              rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              end
            }


            @dashboard.setupScanProgressFrame(@scanner.numChecksPerModule)
            
            @dashboard.setScanStatus("Running")
            @statusBar.setStatusInfo(:text => "Full Scan Running", :color => 'red')
            Thread.new {
              begin               
                @scanner.run(:run_passive_checks => false, :update_sids => true, :update_session => true)
               # logger("scan finished")
            #    @dashboard.setScanStatus("Finished")
            #    @statusBar.statusInfoText = "Ready."
            #    @scan_button.icon = ICON_START
                @scan_running = false
              rescue => bang
              puts bang
              end
            }
          end
        end
      end

      def pauseScan(sender, sel, ptr)
        begin
          if @scanner.running?
          @scanner.stop
          @dashboard.setScanStatus("Scan Paused")
          @statusBar.statusInfoText = "Scan Paused"
          else
          @scanner.continue
          @dashboard.setScanStatus("Scan Running")
          @statusBar.statusInfoText = "Full Scan Running"
          end
        rescue => bang
        puts "!!!ERROR: Could not pause scanner"
        puts bang
        end
      end

      #
      # new_event
      #
      def logger_UNUSED(message)
        @log_viewer.log(LOG_INFO, message)
      end

      def initialize(app)
        # Invoke base class initialize first
        super(app, "WATOBO by siberas (Version: #{Watobo.version})", :opts => DECOR_ALL, :width => 1000, :height => 600)
        #FXToolTip.new(app)
        #app.disableThreads

        self.icon = ICON_WATOBO
        self.show(PLACEMENT_MAXIMIZED)
        self.connect(SEL_CLOSE, method(:onClose))

        @projects = Hash.new

        @scanner = nil
        @iproxy = nil
        @browserView = nil

        @scan_running = false

        @lastViewed = nil # last viewed/selected item (chat/finding)
        @last_request = nil
        @last_response = nil

        @progress_window = Watobo::Gui::ProgressWindow.new(self)
        @settings = {}

        # array for gui plugins. will be filled after project creation.
        @plugins = []
        @app = app
        @progressWindow = nil             # reserved for simple progress Window
        @switcher = nil
        @interceptor = nil

        @table_filter = FXDataTarget.new("")
        @active_project = nil


        @finding_lock = Mutex.new
        @chat_lock = Mutex.new
        @status_lock = Mutex.new

        @finding_queue = []
        @chat_queue = []

        # setup clipboard
        @clipboard_text = ""
        self.connect(SEL_CLIPBOARD_REQUEST) do
        # setDNDData(FROM_CLIPBOARD, FXWindow.stringType, Fox.fxencodeStringData(@clipboard_text))
          setDNDData(FROM_CLIPBOARD, FXWindow.stringType, @clipboard_text + "\x00" )
        end

        menu_bar = FXMenuBar.new(self, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

        file_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "File" , :popupMenu => file_menu_pane)
        @file_new_menu = FXMenuCommand.new(file_menu_pane, "New/Open" )
        @file_new_menu.connect(SEL_COMMAND, method(:onNewProject))

        exit_menu = FXMenuCommand.new(file_menu_pane, "Exit" )
        #FXMenuCommand.new(file_menu_pane, "Exit", nil, getApp(), FXApp::ID_QUIT)
        exit_menu.connect(SEL_COMMAND, method(:onExit))

        FXMenuSeparator.new(file_menu_pane)

        submenu = FXMenuPane.new(self) do |session_menu|
          Watobo::Gui.history.entries.sort_by{ |id, he| he[:last_used] }.reverse.each do |i,h|
            hname = h[:project_name] + " - " + h[:session_name] + " (#{Time.at(h[:last_used]).strftime("%Y-%m-%d %H:%M")})"
            history = FXMenuCommand.new(session_menu, hname )
            history.connect(SEL_COMMAND) do |sender, sel, item|
            #     puts "open session #{h}"
            #     puts "!!!ERROR Could not start session #{h}" if !openSession(h)
              if openSession(:project_name => h[:project_name], :session_name => h[:session_name])
              Watobo::Gui.history.update_usage( :project_name => h[:project_name], :session_name => h[:session_name])
              end

            end
          end
        end
        @file_history = FXMenuCascade.new(file_menu_pane, "Recent Sessions", nil, submenu)
        #load history file

        #  file_open_command = FXMenuCommand.new(file_menu_pane, "Open..." )
        #  file_save_command = FXMenuCommand.new(file_menu_pane, "Save" )
        #  file_save_as_command = FXMenuCommand.new(file_menu_pane, "Save As..." )

        settings_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "Settings" , :popupMenu => settings_menu_pane)
        menu_proxy = FXMenuCommand.new(settings_menu_pane, "Forwarding Proxy..." )
        menu_session = FXMenuCommand.new(settings_menu_pane, "Session Management..." )
        # @active_project ? menu_session.enable : menu_session.disable

        menu_ca = FXMenuCommand.new(settings_menu_pane, "Create Certificate..." )
        menu_ca.connect(SEL_COMMAND, method(:openCADialog))

        menu_preferences = FXMenuCommand.new(settings_menu_pane, "Target Scope..." )
        menu_preferences.connect(SEL_COMMAND, method(:openScopeDialog))

        menu_preferences = FXMenuCommand.new(settings_menu_pane, "Scanner..." )
        menu_preferences.connect(SEL_COMMAND, method(:openScannerSettingsDialog))

        menu_preferences = FXMenuCommand.new(settings_menu_pane, "Interceptor..." )
        menu_preferences.connect(SEL_COMMAND, method(:openInterceptorSettingsDialog))

        www_auth_prefs = FXMenuCommand.new(settings_menu_pane, "WWW-Auth..." )
        www_auth_prefs.connect(SEL_COMMAND) { openWwwAuthDialog() }

        client_cert_prefs = FXMenuCommand.new(settings_menu_pane, "Client Certificates..." )
        client_cert_prefs.connect(SEL_COMMAND) { open_client_cert_dialog() }

        pp_prefs = FXMenuCommand.new(settings_menu_pane, "Password Policy..." )
        pp_prefs.connect(SEL_COMMAND) { openPWPolicyDialog() }
        # intercept_enable = FXMenuCheck.new(settings_menu_pane, "Enable Interception")

        # file_menu_title = FXMenuTitle.new(menu_bar, "Settings" , :popupMenu => settings_menu_pane)

        menu_proxy.connect(SEL_COMMAND, method(:onMenuProxy))
        menu_session.connect(SEL_COMMAND, method(:openSessionManagement))

        tools_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "Tools" , :popupMenu => tools_menu_pane)
        transcoder = FXMenuCommand.new(tools_menu_pane, "Transcoder")
        interceptor = FXMenuCommand.new(tools_menu_pane, "Interceptor")
        transcoder.connect(SEL_COMMAND, method(:onOpenTranscoder))
        interceptor.connect(SEL_COMMAND, method(:onOpenInterceptor))

        view_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "View" , :popupMenu => view_menu_pane)
        view_logs_command = FXMenuCommand.new(view_menu_pane, "Logs" )
        view_dashboard_command = FXMenuCommand.new(view_menu_pane, "Dashboard" )
        view_findings_command = FXMenuCommand.new(view_menu_pane, "Chat-Table")

        view_dashboard_command.connect(SEL_COMMAND, method(:showDashboard))
        view_logs_command.connect(SEL_COMMAND, method(:showLogs))
        view_findings_command.connect(SEL_COMMAND, method(:showConversation))

        window_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "Window" , :popupMenu => window_menu_pane)
        use_small_icons = FXMenuCheck.new(window_menu_pane, "Small Icons/Text" )
        use_small_icons.connect(SEL_COMMAND) {
          if use_small_icons.checked?
          useSmallIcons()
          else
          useRegularIcons()
          end
        }

        help_menu_pane = FXMenuPane.new(self)
        FXMenuTitle.new(menu_bar, "Help" , :popupMenu => help_menu_pane)
        #   menu_lic = FXMenuCommand.new(help_menu_pane, "License" )
        menu_about = FXMenuCommand.new(help_menu_pane, "About" )
        menu_about.connect(SEL_COMMAND) {
        #FXMessageBox.information(self,MBOX_OK,"About", "WATOBO Version 0.9.1!")
          aboutDlg = AboutWatobo.new(self)
          aboutDlg.create
          aboutDlg.show(Fox::PLACEMENT_SCREEN)
        }

        #   top_dock_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        #   tool_bar_shell = FXToolBarShell.new(self)
        #   top_dock_site = FXDockSite.new(top_dock_frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        # bottom_dock_site = FXDockSite.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)

        #  project_bar = FXToolBar.new(top_dock_site, tool_bar_shell, PACK_UNIFORM_WIDTH)
        #  FXToolBarGrip.new(project_bar, :opts => TOOLBARGRIP_SINGLE)
        top_bar = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        project_bar = FXHorizontalFrame.new(top_bar, :opts => LAYOUT_FILL_X|PACK_UNIFORM_WIDTH|FRAME_NONE, :padding => 2)
        @new_project_button = FXButton.new(project_bar, "\tNew Project\tNew Project." , :icon => ICON_ADD_PROJECT, :padding => 0)
        @new_project_button.connect(SEL_COMMAND, method(:onNewProject))

        @scan_button = FXButton.new(project_bar, "\tStart Scan\tStart Scan." ,:opts => FRAME_RAISED|FRAME_THICK, :icon => ICON_START, :padding => 0)
        @scan_button.disable
        # @start_scan_button.tipText = "Start Scan"
        @scan_button.connect(SEL_COMMAND, method(:startFullScan))

        #@pause_scan_button = FXButton.new(project_bar, "\tPause Scan\tPause Scan." ,:icon => ICON_PAUSE)
        #@pause_scan_button.disable
        # @start_scan_button.tipText = "Start Scan"
        #@pause_scan_button.connect(SEL_COMMAND, method(:pauseScan))

        #   views_bar = FXToolBar.new(top_dock_site, tool_bar_shell, :opts => PACK_UNIFORM_WIDTH, :height => 20)
        #   FXToolBarGrip.new(views_bar, :opts => TOOLBARGRIP_SINGLE)

        #@create_report_button = FXButton.new(views_bar,"\tReport\tCreate Report." , :icon => @reportIcon)
        #@create_report_button.disable
        views_bar = project_bar
        @show_dashboard_button = FXButton.new(views_bar, "\tShow Dashboard\tShow Dashboard.", :icon => ICON_DASHBOARD, :padding => 0)
        @show_dashboard_button.connect(SEL_COMMAND, method(:showDashboard))
        # @create_report_button.disable
        @show_conversation_button = FXButton.new(views_bar, "\tShow Conversation\tShow Conversation.", :icon => ICON_CONVERSATION, :padding => 0)
        @show_conversation_button.connect(SEL_COMMAND, method(:showConversation))

        #  tools_bar = FXToolBar.new(top_dock_site, tool_bar_shell, :opts => PACK_UNIFORM_WIDTH)
        #  FXToolBarGrip.new(tools_bar, :opts => TOOLBARGRIP_SINGLE)
        tools_bar = project_bar
        @open_transcoder_button = FXButton.new(tools_bar, "\tOpen Transcoder\tOpen Transcoder.", :icon => ICON_TRANSCODER, :padding => 0)
        @open_transcoder_button.connect(SEL_COMMAND, method(:onOpenTranscoder))

        @btn_show_plugin = FXButton.new(tools_bar, "\tShow Plugins\tShow Plugins.", :icon => ICON_PLUGIN, :padding => 0)
        @btn_show_plugin.connect(SEL_COMMAND, method(:onShowPlugins))

        @open_interceptor_button = FXButton.new(tools_bar, "\tOpen Interceptor\tOpen Interceptor.", :icon => ICON_INTERCEPTOR, :padding => 0)
        @open_interceptor_button.connect(SEL_COMMAND, method(:onOpenInterceptor))
        # dummy button for siberas logo
        FXButton.new(top_bar, nil, :icon => Watobo::Gui::Icons::SIBERAS_ICON, :opts => FRAME_NONE|LAYOUT_SIDE_RIGHT)

        @statusBar = StatusBar.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :padding => 0)

        splitter = FXSplitter.new(self, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING)

        frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|FRAME_SUNKEN, :padding => 0, :width => 200)

        @treeTabbook = FXTabBook.new(frame, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

        ftab = FXTabItem.new(@treeTabbook, "Findings", nil)
        ftab.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        tab_frame = FXVerticalFrame.new(@treeTabbook, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|FRAME_RAISED, :width => 100)
        frame = FXVerticalFrame.new(tab_frame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @findings_tree = Watobo::Gui::FindingsTree.new(frame, self, nil)
        stab = FXTabItem.new(@treeTabbook, "  Sites  ", nil)
        stab.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        tab_frame = FXVerticalFrame.new(@treeTabbook, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|FRAME_RAISED, :width => 100)
        frame = FXVerticalFrame.new(tab_frame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @sites_tree = Watobo::Gui::SitesTree.new(frame, self, nil)

        #   @treeTabbook.connect(SEL_COMMAND) { |sender, sel, item|
        #     case item
        #       when 0
        # if @active_project
        #   @active_project.settings.delete(:site_filter)
        #       updateRequestTable(@active_project)
        #end
        #     end
        #   }
        subscribeFindingsTree()
        subscribeSitesTree()
        #
        # S W I T C H E R
        #

        @switcher = FXSwitcher.new(splitter,LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        # R E Q U E S T I N F O
        requestInfo = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        request_splitter = FXSplitter.new(requestInfo, :opts => LAYOUT_SIDE_TOP|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|LAYOUT_FILL_X|SPLITTER_TRACKING|SPLITTER_REVERSED)

        #conversation_frame = FXVerticalFrame.new(request_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)

        # filterFrame =FXVerticalFrame.new(conversation_frame, LAYOUT_FILL_X)
        #
        # C H A T  F I L T E R  C O N T R O L L E R
        @conversation_table_ctrl = ConversationTableCtrl.new(request_splitter,  :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)

        #==============================================================================================#
        # Chat-Table
        #==============================================================================================#
        #@chatTable = ConversationTable.new(conversation_frame,
        @chatTable = ConversationTable.new(@conversation_table_ctrl )
@conversation_table_ctrl.table= @chatTable

        @chatTable.autoscroll =  true

        @chatTable.connect(SEL_COMMAND) do |sender, sel, item|
          @findings_tree.killSelection()
          @sites_tree.killSelection()
          onTableClick(sender,sel,item)
        end

        @chatTable.connect(SEL_DOUBLECLICKED) do |sender, sel, data|
          @findings_tree.killSelection()
          @sites_tree.killSelection()
          row = sender.getCurrentRow
          if row >= 0 then
          @chatTable.selectRow(row, false)
          chatid = @chatTable.getRowText(row).to_i
          chat = @active_project.getChat(chatid)
          open_manual_request_editor(chat)
          end
        end

        @chatTable.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          @findings_tree.killSelection()
          @sites_tree.killSelection()
          unless event.moved?
            #   row = sender.getCurrentRow
            ypos = event.click_y
            row = @chatTable.rowAtY(ypos)
            #  puts "right click on row #{row} of #{@chatTable.numRows}"
            if row >= 0 and row < @chatTable.numRows then

              @chatTable.selectRow(row, false)
              chatid = @chatTable.getRowText(row).to_i
              chat = @active_project.getChat(chatid)

              showChat(chat)

              FXMenuPane.new(self) do |menu_pane|

              # SEND TO SUBMENU
                submenu = FXMenuPane.new(self) do |sendto_menu|

                  target = FXMenuCommand.new(sendto_menu, "Fuzzer..." )
                  target.connect(SEL_COMMAND) {
                    openFuzzer(chat)
                  }
                  target = FXMenuCommand.new(sendto_menu, "Manual Request..." )
                  target.connect(SEL_COMMAND) {
                    open_manual_request_editor(chat)
                  }

                end
                FXMenuCascade.new(menu_pane, "Send to", nil, submenu)

                # EXCLUDE SUBMENU
                exclude_submenu = FXMenuPane.new(self) do |sub|
                  chat = @active_project.getChat(chatid)

                  target = FXMenuCheck.new(sub, "Chat (#{chatid})" )

                  target.check = @active_project.scan_settings[:excluded_chats].include?(chatid) ? true : false

                  target.connect(SEL_COMMAND) {
                    if target.checked?()
                    @active_project.scan_settings[:excluded_chats].push chatid
                    else
                    @active_project.scan_settings[:excluded_chats].delete(chatid)
                    end

                  }
                #   target = FXMenuCommand.new(sub, "Path" )
                #   target.connect(SEL_COMMAND) {
                # ...
                #   }

                end
                FXMenuCascade.new(menu_pane, "Exclude from Scan", nil, exclude_submenu)

                # COPY SUBMENU
                copy_submenu = FXMenuPane.new(self) do |sub|
                  chat = @active_project.getChat(chatid)
                  url = @active_project.getChat(chatid).request.url
                  #  puts url
                  url_string = "URL: #{url.slice(0,35)}"
                  url_string += "..." if url.length > 36

                  target = FXMenuCommand.new(sub, url_string )
                  target.connect(SEL_COMMAND) {
                    types = [ FXWindow.stringType ]
                    if acquireClipboard(types)
                    puts
                    @clipboard_text = url
                    end

                  }
                  target = FXMenuCommand.new(sub, "Site: #{@active_project.getChat(chatid).request.site}" )
                  target.connect(SEL_COMMAND) {
                    site = @active_project.getChat(chatid).request.site

                    types = [ FXWindow.stringType ]
                    if acquireClipboard(types)
                    @clipboard_text = site
                    end
                  }

                end
                FXMenuCascade.new(menu_pane, "Copy", nil, copy_submenu)

                addToLogin = FXMenuCommand.new(menu_pane, "Add to Login-Script" )
                addToLogin.connect(SEL_COMMAND) {
                  @active_project.add_login_chat_id(chatid)
                  saveSessionSettings(@active_project)
                }

                target = FXMenuCheck.new(menu_pane, "Mark as tested" )
                target.check = chat.tested?
                target.connect(SEL_COMMAND) {
                  chat.tested = target.checked?()
                  Watobo::Utils.saveChat(chat, chat.file)
                }

                FXMenuCommand.new(menu_pane, "Edit comment.." ).connect(SEL_COMMAND) {
                #  puts row

                  dlg = Watobo::Gui::EditCommentDialog.new(self, chat)
                  if dlg.execute != 0 then
                  chat.comment = dlg.comment
                  @chatTable.updateComment(row, dlg.comment)
                  Watobo::Utils.saveChat(chat, chat.file)
                  end
                }
                #  copyRequest = FXMenuCommand.new(menu_pane, "copy Request(#{chatid})" )
                #  copyResponse = FXMenuCommand.new(menu_pane, "copy Response(#{chatid})" )

                #  info = FXMenuCommand.new(menu_pane, "Details..." )
                #info.connect(SEL_COMMAND) { display_info_for(item) }

                menu_pane.create
                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)

              end

            end

          end

        end

        #===================================================================
        # CHAT VIEWER
        #===================================================================
        chat_outer_frame = FXVerticalFrame.new(request_splitter, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_MIN_WIDTH, :padding => 0, :width=>400)
        chat_frame = chat_outer_frame
        #          chat_frame = FXVerticalFrame.new(chat_outer_frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        #view_menu = FXVerticalFrame.new(chat_frame, :opts => LAYOUT_FILL_X, :padding => 0)
        #frame = FXHorizontalFrame.new(view_menu, :opts => LAYOUT_FILL_X)
        #cvlabel = FXLabel.new(frame, "View: ")
        # cvlabel.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

        @quickViewTitle = FXLabel.new(chat_frame, " -N/A- ")
        @quickViewTitle.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        @quickViewSubTitle = FXLabel.new(chat_frame, "")

        frame = FXHorizontalFrame.new(chat_frame, :opts => LAYOUT_CENTER_X|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH, :padding => 0)
        @mre_button = FXButton.new(frame, "Manual Request", ICON_MANUAL_REQUEST_SMALL, nil, 0, :opts => BUTTON_NORMAL|LAYOUT_RIGHT|LAYOUT_FILL_X)
        @mre_button.connect(SEL_COMMAND) {
          open_manual_request_editor(@lastViewed) if @lastViewed
        }
        @mre_button.enabled = false

        @fuzz_button = FXButton.new(frame, "Fuzzer", ICON_FUZZER_SMALL, nil, 0, :opts => BUTTON_NORMAL|LAYOUT_RIGHT|LAYOUT_FILL_X)
        @fuzz_button.connect(SEL_COMMAND) {
          openFuzzer(@lastViewed) if @lastViewed
        }
        @fuzz_button.enabled = false
        @bv_button = FXButton.new(frame, "Browser-View", ICON_BROWSER_SMALL, nil, 0, :opts => BUTTON_NORMAL|LAYOUT_RIGHT|LAYOUT_FILL_X)
        @bv_button.connect(SEL_COMMAND) {
          begin
            if @lastViewed and @browserView then
            openBrowser(@lastViewed.request, @lastViewed.response)
            end
          rescue => bang
          puts bang

          end
        }
        @bv_button.enabled = false

        #  FXHorizontalSeparator.new(chat_frame, :opts => SEPARATOR_GROOVE|LAYOUT_FILL_X)
        #  FXLabel.new(view_menu, "Source:")
        @chat_frame_splitter =  FXSplitter.new(chat_outer_frame, :opts => LAYOUT_SIDE_TOP|SPLITTER_VERTICAL|LAYOUT_FILL_Y|LAYOUT_FILL_X|SPLITTER_TRACKING)
        chat_frame = FXVerticalFrame.new(@chat_frame_splitter, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_MIN_WIDTH|LAYOUT_MIN_HEIGHT, :padding => 0, :width=>400, :height => 400)
        #chat_frame = FXVerticalFrame.new(chat_frame_splitter, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_MIN_WIDTH, :padding => 0, :width=>400)
        title_frame = FXHorizontalFrame.new(chat_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(title_frame, "Request:")

        @request_viewer = Watobo::Gui::RequestViewer.new(chat_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #  @request_viewer = Watobo::Gui::ChatViewer.new(chat_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        # @request_viewer.highlight_style = 1

        # FXHorizontalSeparator.new(chat_frame, :opts => SEPARATOR_GROOVE|LAYOUT_FILL_X)
        chat_frame = FXVerticalFrame.new(@chat_frame_splitter, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_MIN_WIDTH, :padding => 0, :width=>400)
        title_frame = FXHorizontalFrame.new(chat_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(title_frame, "Response:")
        
        @save_response_btn = FXButton.new(title_frame, "Save", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
        @save_response_btn.connect(SEL_COMMAND){ save_response }
        #fxViewButton = FXButton.new(title_frame, "View", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
        #fxViewButton.connect(SEL_COMMAND, method(:onViewResponse))

        # @response_viewer = Watobo::Gui::ChatViewer.new(chat_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @response_viewer = Watobo::Gui::ResponseViewer.new(chat_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        # @response_viewer.highlight_style = 2

        #===================================================================
        # L O G I N F O
        #===================================================================
        logFrame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
        FXLabel.new(logFrame, "Eventlist:", :opts => LAYOUT_FILL_X)
        @log_viewer = LogViewer.new(logFrame, :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        # DASHBOARD#
        @dashboard = Dashboard.new(@switcher)

        # FINDING INFORMATION
        frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        @finding_info = FindingInfo.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        # PLUGIN-BOARD
        @pluginboard = PluginBoard.new(@switcher)

    #    if @foption_nopix.checked? then @doctype_TableFilter.concat(@fext_pix);end
    #    if @foption_nodocs.checked? then @doctype_TableFilter.concat(@fext_docs);end
    #    if @foption_nojs.checked? then @doctype_TableFilter.concat(@fext_javascript);end
    #    if @foption_nocss.checked? then @doctype_TableFilter.concat(@fext_style);end
        
        add_queue_timer(50)
      end

      def create
        super
        # adjust splitters
        frame_height = (@chat_frame_splitter.getSplit(1) + @chat_frame_splitter.getSplit(0)) / 2
        @chat_frame_splitter.setSplit(0, frame_height)
        @chat_frame_splitter.setSplit(1, frame_height )
      end
      # !!!
      #  TODO: FXRUBY-Bug???
      #  If splash screen is shown app will crash on close :(
      # !!!
      # def create
      #   super
      # splash = FXSplashWindow.new(interface, ICON_SPLASH, SPLASH_SHAPED|SPLASH_DESTROY|SPLASH_OWNS_ICON, 2000)
      #splash = FXSplashWindow.new(@app, ICON_SPLASH, SPLASH_SIMPLE, 2000)
      # splash.execute
      # splash.create()
      #splash.show(PLACEMENT_SCREEN)
      # show(PLACEMENT_SCREEN)
      #show(PLACEMENT_MAXIMIZED)

      # end
      private

      def save_response
        unless @last_chat.nil?
        dlg = SaveChatDialog.new(self, @last_chat)
        if dlg.execute != 0
          FXMessageBox.information(self,MBOX_OK,"Response Saved", "The response has been saved to #{dlg.filename}!")
          
        end
        else
          puts "NO CHAT SELECTED!"
        end
      end
      
      def subscribeProject(project)

        project.subscribe(:new_chat){ |c|
          # Thread.new { addChat(c)}
          @chat_lock.synchronize do
          @chat_queue << c
        end
        }

        project.subscribe(:new_finding){ |f|
          # Thread.new { addFinding(f) }
          @finding_lock.synchronize do
          @finding_queue << f
          end
        }

        project.subscribe(:settings_changed){
          saveProjectSettings(project)
          saveSessionSettings(project)
        }
      end

      def subscribeSitesTree()
        @sites_tree.subscribe(:add_site_to_scope){ |site|
          @active_project.addToScope(site)
        }

        @sites_tree.subscribe(:show_conversation){ |chat_list|
          showConversation()
          @chatTable.showConversation(chat_list)
        }

        @sites_tree.subscribe(:show_chat){ |chat|
          showChat(chat)
        }
      end

      def subscribeFindingsTree()
        @findings_tree.subscribe(:add_site_to_scope){ |site|
          @active_project.addToScope(site)
        }

        @findings_tree.subscribe(:delete_domain_filter){ |df|
          @active_project.settings[:domain_filters].delete(df)
          #  puts "Delete Domain-Filter #{df}"
          updateTreeLists()
        }

        @findings_tree.subscribe(:delete_all_domain_filters) {
          @active_project.settings[:domain_filters].clear
          updateTreeLists()
        }

        @findings_tree.subscribe(:vuln_click){ |v| showVulnerability(v) }

        @findings_tree.subscribe(:finding_click){ |v| showFindingDetails(v) }

        @findings_tree.subscribe(:show_finding_details){ |v| showFindingDetails(v) }

        @findings_tree.subscribe(:open_manual_request){ |v| open_manual_request_editor(v) }
        
        @findings_tree.subscribe(:purge_findings){ |f| purge_findings(f) }
        
        @findings_tree.subscribe(:set_false_positive){ |f| set_false_positive(f) }
        
        @findings_tree.subscribe(:unset_false_positive){ |f| unset_false_positive(f) }

      end

      def onClose(sender, sel, event)
        #  puts "! #{Thread.list.length} Threads running"
        response = FXMessageBox.question(self, MBOX_YES_NO, "Finished?", "Are you sure?")
        if response == MBOX_CLICKED_YES
        return 0
        else
        return 1
        end
      end

      def loadProjectSettings(filename=nil)
        settings = nil
        if filename then
          begin
            settings = Hash.new
            settings = Watobo::Utils.loadSettings(filename)
            #            puts settings.to_yaml
          rescue => bang
          puts "!!!ERROR: could not update project settings"
          puts bang
          return false
          end
        end
        return settings
      end

      def loadSessionSettings(filename=nil)
        settings = {}
        return settings if filename.nil?
        if File.exist?(filename) then
          begin
            settings = Watobo::Utils.loadSettings(filename)
          rescue => bang
          puts "!!!ERROR: could not load session settings"
          puts bang
          return false
          end
        else
        puts "! SessionSettings file #{filename} does not exist!"
        end
        return settings
      end

      def onExit(sender, sel, item)
        response = FXMessageBox.question(self, MBOX_YES_NO, "Finished?", "Are you sure?")
        if response == MBOX_CLICKED_YES
        getApp().exit(0)
        end
      end

      def onApplyFilterClick(sender,sel,item)
        applyFilter()

      end

      def onClear(sender, sel, item)
        @table_filter.value =""
        @tableFilterFX.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def onTableClick(sender,sel,item)
        begin
          getApp().beginWaitCursor()
          # purge viewers
          @request_viewer.setText('')
          @response_viewer.setText('')
          row = item.row

          chatid = @chatTable.getRowText(row).to_i
          @chatTable.selectRow(row, false)
          # @logText.appendText("selected ID: (#{chatid})\n")
          @active_project.chats.each do |chat|
            if chat.id == chatid then
               showChat(chat)
            end
          end
        rescue => bang
          puts "!!!ERROR: onTableClick"
          puts bang
          puts "!!!"
        ensure
        getApp().endWaitCursor()
        end
      end

      def onMenuProxy(sender,sel,item)
        if @active_project
          # puts @active_project.settings.to_yaml
          # puts @settings[:password_policy].to_yaml
          proxy_dialog = Watobo::Gui::ProxyDialog.new(self, @active_project.forward_proxy_settings, Watobo::Conf::Gui.dump )
          if proxy_dialog.execute != 0 then
          proxy_prefs = proxy_dialog.getProxyPrefs
          Watobo::Conf::ForwardingProxy.set proxy_prefs
          @active_project.setProxyOptions(YAML.load(YAML.dump(proxy_prefs)))
          puts "* current proxy:\n> #{@active_project.getCurrentProxy()}" if $DEBUG
          
          Watobo::Gui.save_default_settings(@active_project)
          
          saveProjectSettings(@active_project)
         
          update_status_bar(@active_project)
          #puts "* current proxy:\n> #{@active_project.getCurrentProxy().to_yaml}"
          #puts @settings[:password_policy].to_yaml
          end
        else
        FXMessageBox.information(self,MBOX_OK,"No Project Defined", "Create Project First")
        end
      end

      def purge_findings(findings)
        return false if @active_project.nil?
        findings.each do |f|
          @active_project.delete_finding(f)
        end
      end
      
      def set_false_positive(findings)
        return false if @active_project.nil?
        findings.each do |f|
          @active_project.set_false_positive(f)
        end
      end
      
      def unset_false_positive(findings)
        return false if @active_project.nil?
        findings.each do |f|
          @active_project.unset_false_positive(f)
        end
      end
    end # Class End

  end
end
