# .
# project.rb
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
  class Conversation
    include Watobo::Constants
    attr_accessor :file
    def id()
      # must be defined
    end

    def copyRequest()
      # req_copy = []
      # self.request.each do |line|
      #   req_copy.push line.clone
      # end
      copy = Utils.copyObject(@request)
      # now extend the new request with the Watobo mixins
      copy.extend Watobo::Mixin::Parser::Url
      copy.extend Watobo::Mixin::Parser::Web10
      copy.extend Watobo::Mixin::Shaper::Web10
      return copy
    end

    private

    def extendRequest
      @request.extend Watobo::Mixin::Shaper::Web10
      @request.extend Watobo::Mixin::Parser::Web10
      @request.extend Watobo::Mixin::Parser::Url
    end

    def extendResponse
      @response.extend Watobo::Mixin::Parser::Web10
    end

    def initialize(request, response)
      @request = request
      @response = response
      @file = nil

      extendRequest()
      extendResponse()

    end

  end

  class Chat < Conversation
    attr :request
    attr :response
    attr :settings

    @@numChats = 0
    @@max_id = 0

    @@lock = Mutex.new

    public
    def resetCounters()
      @@numChats = 0
      @@max_id = 0
    end

    def tested?()
      return false unless @settings.has_key?(:tested)
      return @settings[:tested]
    end

    def tested=(truefalse)
      @settings[:tested] = truefalse
    end

    def tstart()
      @settings[:tstart]
    end

    def tstop()
      @settings[:tstop]
    end

    def id()
      @settings[:id]
    end

    def comment=(c)
      @settings[:comment] = c
    end

    def comment()
      @settings[:comment]
    end

    def source()
      @settings[:source]
    end

    # INITIALIZE ( request, response, prefs )
    # prefs:
    #   :source - source of request/response CHAT_SOURCE
    #   :id     - an initial id, if no id is given it will be set to the @@max_id, if id == 0 counters will be ignored.
    #   :start  - starting time of request format is Time.now.to_f
    #   :stop   - time of loading response has finished
    #   :
    def initialize(request, response, prefs = {})

      begin
        super(request, response)

        @settings = {
          :source => CHAT_SOURCE_UNDEF,
          :id => -1,
          :start => 0,
          :stop => -1,
          :comment => '',
          :tested => false
        }

        @settings.update prefs
        #  puts @settings[:id].to_s

        @@lock.synchronize{
        # enter critical section here ???
          if @settings[:id] > @@max_id
            @@max_id = @settings[:id]
          elsif @settings[:id] < 0
            @@max_id += 1
            @settings[:id] = @@max_id
          end
          @@numChats += 1
        # @comment = ''
        # leafe critical section here ???
        }

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

  end

  class Finding < Conversation

    @@numFindings = 0
    @@max_id = 0

    @@lock = Mutex.new

    attr :details
    attr :request
    attr :response
    def resetCounters()
      @@numFindings = 0
      @@max_id = 0
    end

    def id()
      @details[:id]
    end
    
    def false_positive?
      @details[:false_positive]
    end
    
    def set_false_positive
      @details[:false_positive] = true
    end
    
    def unset_false_positive
      @details[:false_positive] = false
    end

    def initialize(request, response, details = {})
      super(request, response)
      @details = {
        :id => -1,
        :comment => '',
        :false_positive => false    # FalsePositive
      }

      @details.update details if details.is_a? Hash

      @@lock.synchronize{
      # enter critical section here ???
        if @details[:id] > 0 and @details[:id] > @@max_id
          @@max_id = @details[:id]
        elsif @details[:id] < 0
          @@max_id += 1
          @details[:id] = @@max_id
        end
        @@numFindings += 1

      }
      extendRequest()
      extendResponse()

    end

  end

  class Project
    
    attr :chats
    attr_accessor :findings
    attr :scan_settings
    attr :forward_proxy_settings
    attr :date
    attr :project_name
    attr :session_name
    attr :session_store
    attr_accessor :settings

    attr :active_checks
    attr :passive_checks
    attr_accessor :plugins
    attr_accessor :excluded_chats

    attr :target_filter
    def subscribe(event, &callback)
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def notify(event, *args)
      if @event_dispatcher_listeners[event]
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

    def sessionSettingsFile
      @session_file
    end

    def projectSettingsFile
      @project_file
    end

    def getLoginChats()
      @scan_settings[:login_chat_ids] ||= []
      login_chats = []
      @scan_settings[:login_chat_ids].each do |cid|
        chat = getChat(cid)
        login_chats.push chat if chat
      end
      login_chats
    end

    def getWwwAuthentication()
      @scan_settings[:www_auth]
    end

    def getLoginChatIds()
      #p @settings[:login_chat_ids]
      # p @settings.to_yaml
      @scan_settings[:login_chat_ids] ||= []
      @scan_settings[:login_chat_ids]
    end

    def setLoginChatIds(ids)
      @scan_settings[:login_chat_ids] = ids if ids.is_a? Array
    end

    def getSidPatterns
      @scan_settings[:sid_patterns]
    end

    def setProxyOptions(proxy_prefs)
      @forward_proxy_settings = proxy_prefs

      @sessionController.addProxy(getCurrentProxy())
    end

    # gives the currently selected proxy
    # format <host>:<port>
    def getCurrentProxy()
      c_proxy = nil
      begin
        name = @forward_proxy_settings[:default_proxy]
        cproxy = @forward_proxy_settings[name]
        return cproxy
      rescue
        puts "! no proxy settings available"
      end
      return nil
    end

    def setSidPatterns(sp)
      @scan_settings[:sid_patterns] = sp if sp.is_a? Array
    end

    def getLogoutSignatures
      @scan_settings[:logout_signatures]
    end

    def getCSRFPatterns
      @scan_settings[:csrf_patterns]
    end

    # setCSRFRequest
    # =Parameters
    # request: test request which requires csrf handling
    # ids:      csrf request ids of current conversation
    # patterns: csrf patterns for identifiying and updating tokens
    def setCSRFRequest(request, ids, patterns=[])
      puts "* setting CSRF Request"
      # puts request.class
      #  puts request
      urh = uniqueRequestHash(request)
      @scan_settings[:csrf_request_ids][urh] = ids
      @scan_settings[:csrf_patterns].concat patterns unless patterns.empty?
      @scan_settings[:csrf_patterns].uniq!
      notify(:settings_changed)
    end

    def getCSRFRequestIDs(request)
      urh = uniqueRequestHash(request)
      @scan_settings[:csrf_request_ids] ||= {}
      ids = @scan_settings[:csrf_request_ids][urh]
      # puts "* found csrf req ids #{ids}"
      ids = [] if ids.nil?
      ids
    end

    def setLogoutSignatures(ls)
      @scan_settings[:logout_signatures] = ls if ls.is_a? Array
    end

    # Helper function to get all necessary preferences for starting a scan.
    def getScanPreferences()
      settings = {
        :smart_scan => @scan_settings[:smart_scan],
        :non_unique_parms => @scan_settings[:non_unique_parms],
        :excluded_parms => @scan_settings[:excluded_parms],
        :sid_patterns => @scan_settings[:sid_patterns],
        :csrf_patterns => @scan_settings[:csrf_patterns],
        :run_passive_checks => false,
        :login_chat_ids => [],
        :proxy => getCurrentProxy(),
        :login_chats => getLoginChats(),
        :max_parallel_checks => @scan_settings[:max_parallel_checks],
        :logout_signatures => @scan_settings[:logout_signatures],
        :custom_error_patterns => @scan_settings[:custom_error_patterns],
        :scan_session => self.object_id,
        :www_auth => @scan_settings[:www_auth].nil? ? Hash.new : @scan_settings[:www_auth],
        :client_certificates => @scan_settings[:client_certificates],
        :session_store => @session_store
      }
      return settings
    end

    # returns a project/session specific ID needed for synchronising Sessions
    def getSessionID()
      sid = @settings[:project_name] + @settings[:session_name]
      return sid
    end

    def getClientCertificates()
      client_certs = @settings[:client_certificates]
    end

    def setClientCertificates(certs)
      @scan_settings[:client_certificates] = certs
    end

    def add_client_certificate(client_cert={})
      return false unless client_cert.is_a? Hash
      [ :site, :certificate_file, :key_file].each do |p|
        return false unless client_cert.has_key? p
      end
      cs = @scan_settings[:client_certificates]
      site = client_cert[:site]
      if cs.has_key? site
        cs[site][certificate] = nil
        cs[site][key] = nil

      end

    end

    def client_certificates=(certs)
      @scan_settings[:client_certificates] = certs
      cs = @scan_settings[:client_certificates]
      cs.each_key do |site|
        unless cs[site].has_key? :ssl_client_cert
          crt_file = cs[site][:certificate_file]
          if File.exist?(crt_file)
            puts "* loading certificate #{crt_file}" if $DEBUG
            cs[site][:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(crt_file))
          end
        end

        unless cs[site].has_key? :ssl_client_key
          key_file = cs[site][:key_file]
          if File.exist?(key_file)
            puts "* loading private key #{key_file}" if $DEBUG
            password = cs[site][:password].empty? ? nil : cs[site][:password]
            cs[site][:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(key_file), password)
          end
        end
      end
    end

    def getScanPolicy()
      @settings[:policy]
    end

    def uniqueRequestHash(request)
      begin
        hashbase = request.site + request.method + request.path
        request.get_parm_names.sort.each do |p|
          if @scan_settings[:non_unique_parms].include?(p) then
          hashbase += p + request.get_parm_value(p)
          else
          hashbase += p
          end

        end
        request.post_parm_names.sort.each do |p|
          if @scan_settings[:non_unique_parms].include?(p) then
          hashbase += p + request.post_parm_value(p)
          else
          hashbase += p
          end

        end
        return Digest::MD5.hexdigest(hashbase)
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        return nil
      end
    end

    def last_chatid
      if @chats.length > 0
      return @chats.last.id
      else
      return 0
      end
    end

    def extendRequest(request)
      request.extend Watobo::Mixin::Shaper::Web10
      request.extend Watobo::Mixin::Parser::Web10
      request.extend Watobo::Mixin::Parser::Url
    end

    def extendResponse(response)
      response.extend Watobo::Mixin::Shaper::Web10
      response.extend Watobo::Mixin::Parser::Web10
      response.extend Watobo::Mixin::Parser::Url

    end

    def updateSettings(new_settings)
      #  new_settings.keys.each do |k|
      #    @settings[k] = new_settings[k]
      #  end
      @scan_settings.update new_settings
    end

    
    def findChats(site, opts={})
      o = {
        :dir => "",
        #:file => nil,
        :method => nil,
        :max_count => 0
      }
      o.update opts
      o[:dir].strip!
      o[:dir].gsub!(/^\//,"")

      matches = []
      @chats.each do |c|
        if c.request.site == site then
          matches.push c if o[:dir] == c.request.dir
        end
        return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
      end
      return matches
    end

    def getChat(chatid)
      #TODO: Improvement for faster results => Fuzzy-Logic
      @chats.each do |c|
        if c.id.to_s == chatid.to_s then
        return c
        end
      end
      return nil
    end

    def projectName
      @settings[:project_name]
    end

    def sessionName
      @settings[:session_name]
    end

    def interceptPort
      @settings[:project_name]
    end

    # runs passive checks on specific chat
    def runPassiveChecks(chat)
      tlist = []
      @passive_checks.each do |test_module|

        tlist << Thread.new(chat, test_module) {|c,m|
          m.do_test(c)
        }
      end
      return tlist
    end

    def addChat(chat, prefs={})
      @chats_lock.synchronize do 
      begin
        if chat.request.host then
          chats.push chat

          options = {
            :run_passive_checks => true,
            :notify => true
          }
          options.update prefs

          runPassiveChecks(chat) if options[:run_passive_checks] == true

          #@interface.addChat(self, chat) if @interface
          notify(:new_chat, chat) if options[:notify] == true

          if chat.id != 0 then
          @session_store.add_chat(chat)
          else
            puts "!!! Could not add chat #{chat.id}"
          end
        end
        # p "!P!"
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      end
    end

    def runLogin
      @sessionMgr.runLogin(loginChats)
    end

   def has_scope?()
      return false if @scan_settings[:scope].nil?
      @scan_settings[:scope].each_key do |k|
        return true if @scan_settings[:scope][k][:enabled] == true
      end
      return false
    end

    def scope
      @scan_settings[:scope]
    end

    def scope=(scope)
      @scan_settings[:scope] = scope
    end

    def setScope(scope)
      @scan_settings[:scope] = scope
    end

    def setWwwAuthentication(www_auth)
      @scan_settings[:www_auth] = www_auth
    end

    def setCSRFPatterns(patterns)
      @scan_settings[:csrf_patterns] = patterns
    end

    def add_login_chat_id(id)
      @scan_settings[:login_chat_ids] ||= []
      @scan_settings[:login_chat_ids].push id
    end

    def addToScope(site)
      return false if !@scan_settings[:scope][site].nil?

      scope_details = {
        :site => site,
        :enabled => true,
        :root_path => '',
        :excluded_paths => [],
      }

      @scan_settings[:scope][site] = scope_details
      return true
    end

    def addFinding(finding, opts={})
      @findings_lock.synchronize do
      options = {
        :notify => true,
        :save_finding => true
      }
      options.update opts
      #  puts "* add finding #{finding.details[:fid]}" if $DEBUG

      unless @findings.has_key?(finding.details[:fid])
        begin
          @findings[finding.details[:fid]] = finding
          #@interface.addFinding(new_finding)
          #   puts "* new finding"
          notify(:new_finding, finding) if options[:notify] == true

          @session_store.add_finding(finding) if options[:save_finding] == true
        rescue => bang
          puts "!!!ERROR: #{Module.nesting[0].name}"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
      end

    end
    
    def delete_finding(f)
      @findings_lock.synchronize do
        @session_store.delete_finding(f)
        @findings.delete f.details[:fid]
      end
    end
    
    def set_false_positive(finding)
      @findings_lock.synchronize do
        puts "Set Finding #{finding.id} / #{finding.details[:fid]} False-Positive" if $DEBUG
        if @findings.has_key? finding.details[:fid]
          @findings[finding.details[:fid]].set_false_positive
          @session_store.update_finding(finding)
          return true
        end
        return false
      end
    end
    
    def unset_false_positive(finding)
      @findings_lock.synchronize do
        if @findings.has_key? finding.id
          @findings[finding.id].unset_false_positive
          @session_store.update_finding(finding)
          return true
        end
        return false
      end
    end


    def setupProject(progress_window=nil)
      begin
        puts "DEBUG: Setup Project" if $DEBUG and $debug_project
        importSession()
=begin
        importSession(progress_window)

        init_active_modules(progress_window)

        init_passive_modules(progress_window)

        initPlugins(progress_window)
=end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    # returns all chats which are in the target scope

    def chatsInScope(chats=nil, scope=nil)
      scan_prefs = @scan_settings
      unique_list = Hash.new
      chatlist = chats.nil? ? @chats : chats
      new_scope = scope.nil? ? scan_prefs[:scope] : scope
      # puts new_scope.to_yaml
      cis = []
      chat_in_scope = nil
      chatlist.each do |chat|
        next if scan_prefs[:excluded_chats].include?(chat.id)
        uch = uniqueRequestHash(chat.request)

        next if unique_list.has_key?(uch) and scan_prefs[:smart_scan] == true
        unique_list[uch] = nil

        chat_in_scope = chat
        # filter by targets first
        new_scope.each do |s, c_scope|
          chat_in_scope = nil

          if chat.request.site == c_scope[:site] then
            chat_in_scope = chat

            if chat_in_scope and c_scope[:root_path] != ''
              chat_in_scope = ( chat.request.path =~ /^(\/)?#{c_scope[:root_path]}/i ) ? chat : nil
            end

            if chat_in_scope and c_scope[:excluded_paths] and c_scope[:excluded_paths].length > 0
              c_scope[:excluded_paths].each do |p|
                if ( chat.request.url =~ /#{p}/i )
                  chat_in_scope = nil
                break
                end
              end
            end
          end
          cis.push chat_in_scope unless chat_in_scope.nil?
        end
      end
      cis
    end

    def siteInScope?(site)
      #in_scope = false
      @scan_settings[:scope].keys.each do |scope_site|
        return true if scope_site == site
      end
      return false
    end

    def siteSSL?(site)
      @chats.each do |c|
        if c.request.site == site
          return true if c.request.proto =~ /https/
        return false
        end
      end
    end

    #
    # I NITIALIZE
    #
    #
    def initialize(project_settings)

      puts "DEBUG: Initializing Project" if $DEBUG
      @event_dispatcher_listeners = Hash.new
      @settings = {}

      @active_checks = []
      @passive_checks = []
      @plugins = []

      @chats = []
      @findings = Hash.new
      @findings_lock = Mutex.new
      @chats_lock = Mutex.new

      # puts project_prefs.to_yaml
      #setDefaults()

      # reset counters
      Watobo::Chat.new([],[]).resetCounters
      Watobo::Finding.new([],[]).resetCounters

      # UPDATE SETTINGS
      @settings.update(project_settings)

      @scan_settings = Watobo::Conf::Scanner.dump
      @forward_proxy_settings = Watobo::Conf::ForwardingProxy.dump

      raise ArgumentError, "No SessionStore Defined" unless @settings.has_key? :session_store

      @session_store = @settings[:session_store]
      #  @passive_checks = @settings[:passive_checks] if @settings.has_key? :passive_checks

      @settings[:passive_checks].each do |pm|
        pc = pm.new(self)
        pc.subscribe(:new_finding){ |nf| addFinding(nf) }
        @passive_checks << pc
      end

      #      @active_checks = @settings[:active_checks]
      @settings[:active_checks].each do |am|
        ac = am.new(self)
        ac.subscribe(:new_finding){ |nf| addFinding(nf) }
        @active_checks << ac
      end

      @date = Time.now.to_i
      # @date_str = Time.at(@date).strftime("%m/%d/%Y@%H:%M:%S")

      @sessionController = Watobo::Session.new(self)

      @sessionController.addProxy(getCurrentProxy())

    end

    #
    # S E S S I O N _ I N I T
    #

    def listSites(prefs={}, &block)
      list = Hash.new

      cprefs = { :in_scope => false,
        :ssl => false
      }
      cprefs.update prefs

      @chats.each do |chat|
        next if list.has_key?(chat.request.site)
        site = chat.request.site
        site = nil if cprefs[:in_scope] == true and not siteInScope?(site)
        site = nil if cprefs[:ssl] and not siteSSL?(site)
        unless site.nil?
          yield site if block_given?
          list[site] = nil
        end
      #  yield chat.request.site if chat.request.site
      end
      return list.keys
    end

    def listDirs(site, list_opts={}, &block)
      opts = { :base_dir => "",
        :include_subdirs => true
      }
      opts.update(list_opts) if list_opts.is_a? Hash
      list = Hash.new
      @chats.each do |chat|
        next if chat.request.site != site
        next if list.has_key?(chat.request.path)
        next if opts[:base_dir] != "" and chat.request.path !~ /^#{Regexp.quote(opts[:base_dir])}/
        subdirs = chat.request.subDirs
        subdirs.each do |dir|
          next if dir.nil?
          next if list.has_key?(dir)
          list[dir] = :path
          if opts[:include_subdirs] == true then
          yield dir if block
          else
            d = dir.gsub(/#{Regexp.quote(opts[:base_dir])}/,"")
            yield dir unless d =~ /\// and block
          # otherwise it is a subdir of base_dir
          end
        end
      end
    end

    private

    def listChatIds(path, pattern)
      id_list = []
      Dir.foreach(path) do |file|
        if file =~ /#{pattern}/ then
          id = file.gsub!(/-#{pattern}/,'').to_i
        id_list.push id
        end
      end
      return id_list.uniq.sort
    end

    def importSession()
      num_chats = @session_store.num_chats
      num_findings = @session_store.num_findings
      num_imports = num_chats + num_findings
      notify(:update_progress, :progress => 0, :total => num_imports, :task => "Import Conversation")
      @session_store.each_chat do |c|
        notify(:update_progress, :increment =>1, :job => "chat #{c.id}" )
        addChat(c, :run_passive_checks => false, :notify => false ) if c
      end

      notify(:update_progress, :task => "Import Findings")
      @session_store.each_finding do |f|
        notify(:update_progress, :increment =>1, :job => "finding #{f.id}" )
        addFinding(f, :notify => true, :save_finding => false ) if f
      end
=begin
    puts "* Import Session:"
    puts "+ Conversation Path:\n>> #{File.expand_path(@conversations_path)}"

    puts
    chatIds = listChatIds(@conversations_path, "chat")
    findingIds = listChatIds(@findings_path, "finding")

    numChats = chatIds.length
    numFindings = findingIds.length
    numImports = numChats + numFindings
    pc = 0

    notify(:update_progress, :total => numImports, :task => "Import Conversation")

    begin
    chatIds.each_with_index do |id, index|

    notify(:update_progress, :increment =>1, :job => "chat #{index}/#{numChats}" )

    fname = File.join(@conversations_path, "#{id}-chat")
    chat = Watobo::Utils.loadChatYAML(fname)
    addChat(chat, :run_passive_checks => false, :notify => false ) if chat
    end
    rescue => bang
    puts "!!!ERROR: Could not import conversations"
    puts bang
    puts bang.backtrace if $DEBUG
    end

    puts "+ Findings Path:\n>> #{File.expand_path(@findings_path)}"

    notify(:update_progress, :task => "Import Findings")
    begin
    findingIds.each_with_index do |id, index|
    notify(:update_progress, :increment => 1, :job => "Finding #{index}/#{numFindings}")

    fname = File.join(@findings_path, "#{id}-finding")
    finding = Watobo::Utils.loadFindingYAML(fname)

    addFinding(finding, :notify => false) if finding

    end
    rescue => bang
    puts "!!!ERROR: Could not import finding [#{id}]"
    puts bang

    end
=end
    end

    def setDefaults_UNUSED()
      @settings = {
        :excluded_chats => [],
        :scope => Hash.new,
        #:project_prefs => {
        #     :project_settings_file_ext => '.wps',
        #    :session_settings_file_ext => '.wss',
        :project_path => '',
        :session_path => '',
        :project_name => '',
        :session_name => '',
        :module_dir => 'modules',
        :plugin_dir => 'plugins',
        :conversations_dir => "conversations",
        :findings_dir => "findings",
        :logs_dir => "logs",
        #},

        #:scan_prefs => {
        :custom_error_patterns => [],
        :max_parallel_checks => 15,
        :excluded_parms => [ "__VIEWSTATE", "__EVENTVALIDATION"],
        :non_unique_parms => [],
        :smart_scan => true,
        :run_passive_checks => false,
        #},
        :policy => { :name => 'Default',
          :list => {
            'Default' => {
              'Watobo::Modules::Active::Directories::Dir_indexing' => false,
              'Watobo::Modules::Active::Discovery::Http_methods' => false,
              'Watobo::Modules::Active::Domino::Domino_db' => false,
              'Watobo::Modules::Active::Sap::Its_commands' => false,
              'Watobo::Modules::Active::Sap::Its_services' => false,
              'Watobo::Modules::Active::Sap::Its_service_parameter' => false,
              'Watobo::Modules::Active::Sap::Its_xss' => false,
              'Watobo::Modules::Active::Sqlinjection::Sqli_simple' => true,
              'Watobo::Modules::Active::Sqlinjection::Sql_boolean' => true,
              'Watobo::Modules::Active::Sqlinjection::Sql_numerical' => false,
              'Watobo::Modules::Active::Xss::Xss_simple' => true,
            }
          }
        },

        #@interface = Hash.new
        #:session_management => {
        :csrf_patterns => [
          "name=\"(token)\" value=\"([0-9a-zA-Z!-]*)\"",
          "(token)=([-0-9a-zA-Z_:]*)(;|&)?"
        ],
        :csrf_request_ids => Hash.new,

        :login_chat_ids => [],
        :sid_patterns => [
          "name=\"(sessid)\" value=\"([0-9a-zA-Z!-]*)\"",
          "(sessid)=([-0-9a-zA-Z_:]*)(;|&)?",
          '(SESSIONID)=([-0-9a-zA-Z_:\.\(\)]*)(;|&)?',
          "(PHPSESSID)=([0-9a-zA-Z]*)(;|&)?",
          '(ASPSESSIONID)\w*=([0-9a-zA-Z]*)(;|&)?',
          '(ASP.NET_SessionId)=([0-9a-zA-Z]*)(;|&)?',
          "(MYSAPSSO2)=([0-9a-zA-Z.=%]*)(;|&)?",
          "(ELEXIRSID)=([0-9a-zA-Z!-]*)(;|&)?",
          "(SLSID)=([0-9a-zA-Z!-]*)(;|&)?",
          "(sid)=([0-9a-z]*)(')?", #servlet?sid=9912ad967cc578a12ada85d91f841e18')
          '(saplb_\*)=([-0-9a-zA-Z_:\(\)]*)(;|&)?',
          "(DomAuthSessId)=([0-9a-zA-Z]*)(;|&)?",
          '(wgate)\/([\w]{4,}\/[\w=~]*)(;|&|\'|")?', # SAP ITS WGATE Session Handling
          '(session)=([-0-9a-zA-Z_:\.]*)(;|&)?'       # SAP ITS Session Cookie
        ],
        :logout_signatures => [
          "^Location.*login"
        ],
        #},

        #      :settings => {
        #        :module_path => ''
        #      },
        :history => [],
        :www_auth => {},
        :client_certificates => {} # e.g. { :site => { :certificate_file => "host.crt", :key_file => "host.key", :password => "lkajsdflk" }
      }
    end

    private

  end
end # Watobo
