# .
# browser_preview.rb
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
    class BrowserControl
      def initialize()

      end

      def navigate(url)
        raise "Navigate-Method not defined"
      end

      def connect()
        # check if browser is controlable. If not, create new instance.
        raise "Connect-Method not defined"
      end

      def ready?()
        # running? can be controlled?
      end

      def busy?()
        # wait until loading url has finished
      end

      def getDoc()
        raise "GetDocument-Method not defined"
      end

      def close()

      end

      def visible=(status)

      end

      def watobo_enabled?()
        # check if necessary plugins, etc. are installed
        # e.g. jssh for Firefox
      end
    end

    #
    # Firefox Controller Class
    #
    class FFControl_UNUSED < BrowserControl
      #@@fft = nil
      def initialize()
        @jssh = nil
        aquireSession()
      end

      def ready?()
        return false if @jssh == nil
        begin
          @jssh.cmd(""){ |s| print s }
        rescue
          @jssh = nil
          return false
        end

        return true
      end

      def navigate(url)
        # puts "* Firefox.navigate"
        if aquireSession() then
          res = ""
          @jssh.cmd("tabBrowser.loadURI(\"#{url}\")"){ |l|
            print l
            res += l
          }
          if res.split(/\n/).first =~ /Error:/i then
            @jssh.cmd("var tab = browser.addTab(\"#{url}\")"){ |s| print s }
            @jssh.cmd("var tabBrowser = browser.getBrowserForTab(tab)"){ |s| print s }
          end

        end
      end

      def getDoc()
        begin
          aquireSession()

          jssh_cmd = "var doc = tabBrowser.contentDocument;"
          @jssh.cmd(jssh_cmd){ |s| print s }

          jssh_cmd = "var body = doc.body;"
          @jssh.cmd(jssh_cmd){ |s| print s }
          @jssh.cmd("body"){ |s| print s }

          jssh_cmd = "body.innerHTML;"
          doc = @jssh.cmd(jssh_cmd)
          puts doc
          return doc

        rescue => bang
          puts bang
          return false

        end

      end

      def busy?()
        ffcmd = "tabBrowser.webProgress.isLoadingDocument"
        res = ""
        begin

          if ready?() then

            res = ""
            @jssh.cmd(ffcmd) {|s| res += s}

            return true if res =~ /true/
          end

          return false

        rescue => bang
          puts bang
          return false
        end
      end

      def connect()
        aquireSession()
      end

      def close()
        if ready?
          @jssh.cmd("browser.removeTab(tab)"){ |s| print s }
        end
      end

      private

      def aquireSession()

        if not ready?
          @jssh = nil
          @jssh = ffconnect("127.0.0.1", "9997")
        end

        if @jssh != nil then
          @jssh.cmd("var w0 = getWindows()[0]"){ |s| print s }
          @jssh.cmd("var browser = w0.getBrowser()"){ |s| print s }
          @jssh.cmd("browser"){ |s| print s }

          #jssh.cmd("browser.loadURI(\"http://www.siberas.de\")"){ |s| print s }
        else
          return false
        end
      end

      def startFireFox()
        puts "startFireFox()"
        path_to_firefox = ""
        case RUBY_PLATFORM
        when /mswin|mingw|bccwin/
          puts "* firefox on this platform (#{RUBY_PLATFORM}) not supported, yet!"
        when /linux|bsd|solaris|hpux/i
          path_to_firefox = `which firefox`.strip
        when /darwin/i
          path_to_firefox = '/Applications/Firefox.app/Contents/MacOS/firefox'
        else
          puts "!Unknown OS???"
          nil
        end
        if path_to_firefox != ""
          puts "* trying to start firefox (#{path_to_firefox})"
          Thread.new { system("#{path_to_firefox} -jssh")}
        end
      end

      def ffconnect(host, port)
        retry_count = 0

        begin
          puts "* connecting to firefox jssh extension"
          jssh = Net::Telnet.new('Host' => host,
          'Port' => port)
          jssh.sync = true

          jssh.waitfor(/>/){ |s| print s }
        rescue Errno::ECONNREFUSED
          puts "! BrowserControl: Connection Reset"

          if retry_count < 1 then
            retry_count += 1
            startFireFox()
            retry
          elsif retry_count < 3 then
            retry_count += 1
            # startFireFox()
            sleep 1.0
            retry
          else
            puts "!!! Seems like JSSH is not installed !!!"
            puts "please check the installation instructions!"
            raise "JSSH_CONNECT_ERROR"
          end
        rescue => bang
          puts "!!! Could not create FireFoxControl !!!"
          puts bang
          return false
        end

        return jssh
      end
    end

    #
    # InternetExplorer Controller Class
    #
    class IEControl < BrowserControl
      #    include WIN32OLE::VARIANT
      def initialize()
        @ie = nil
        createBrowser()

      end

      def createBrowser()
        @ie = WIN32OLE.new('InternetExplorer.Application')

        @ie.menubar=0
        @ie.toolbar=0
        @ie.statusbar=0
        @ie.visible = true
      end

      def busy?()
        @ie.busy()
      end

      def connect()
        createBrowser()
      end

      def navigate(url)

        @ie.navigate(url)
      end

      def visible=(status)
        @ie.visible = status
      end

      def getDoc()
        @ie.document.body.innerHTML.to_s
      end

      def close()
        @ie.Quit
        @ie = nil
      end

      def ready?()
        return false if @ie.nil?
        begin
          @ie.visible = true
        rescue => bang
          puts bang
          return false
        end
        return true
      end
    end

    class SeleniumRC < BrowserControl
      def initialize(browser_type = :firefox, prefs = {})
        proxy = "127.0.0.1:8081"
        @rc = nil
        proxy = prefs[:proxy] if prefs.has_key? :proxy
        begin
          #  require 'selenium-webdriver'
          @rc = createBrowser(browser_type, proxy)
        rescue => bang
          puts "* Could not create selenium driver"
        end
      end

      def createBrowser( browser_type = :firefox, proxy = nil )
        profile = nil
        unless proxy.nil?
          puts "* create preview with proxy #{proxy}"
          profile = Selenium::WebDriver::Firefox::Profile.new

          driver_proxy = Selenium::WebDriver::Proxy.new(:http => proxy)
          profile.proxy = driver_proxy

          @rc = Selenium::WebDriver.for :firefox, :profile => profile

        else
          @rc = Selenium::WebDriver.for browser_type
        end
      end

      def busy?()
        false
      end

      def connect()
        createBrowser()
      end

      def navigate(url)
        @rc.navigate.to(url)
      end

      def visible=(status)

      end

      def getDoc()
        @rc.page_source
      end

      def close()
        @rc.quit

      end

      def ready?()

        begin
          return false if @rc.nil?

        rescue => bang
          puts bang
          return false
        end
        return true
      end
    end

    class BrowserPreview
      attr_accessor :proxy
      def show(request, response)
        begin
          if watoboProxy? then
            hashid = @proxy.addPreview(response)
            url = request.url
            url += request.query != '' ? '&' : '?'
            url += "WATOBOPreview=#{hashid}"
            @browser.navigate(url) if hashid
            return url
          else
            raise "WRONG_PROXY_SETTINGS"
          end
        rescue => bang
          puts bang
          #   puts bang.class
          #  puts bang.backtrace if $DEBUG
          raise bang
        end
        #raise "Wrong Proxy Settings"
      end

      def initialize(proxy)
        @proxy = proxy
        @browser = nil

      end

      private

      def wait()
        while @browser.busy? == true
          #puts "sleep, browser sleep ..."
          sleep 0.5
        end
      end

      def watoboProxy?

        aquireBrowser()

        begin
          #@browser.visible = false
          url = "http://watobo.localhost/?WATOBOPreview=ProxyTest"
          timeout(5.0) do
            @browser.navigate(url)
            #sleep 1
            wait()
          end
          puts "* check proxy"
          if @browser.getDoc() =~ /PROXY_OK/ then
            return true
          end

        rescue Timeout::Error
          puts "!!! Proxy Connection Timed out"
        rescue => bang
          puts "!!! Could not connect to proxy."
          puts bang
          puts bang.backtrace if $DEBUG
          aquireBrowser(true)
          retry
        end
      #  @browser.close
        
        return false

      end

      def aquireBrowser( force = false )
        if @browser.nil? or force == true then
# TODO: initialize a global GUI function on startup to check if necessary gems are installed
          case RUBY_PLATFORM
          when /mswin|mingw|bccwin/
            require 'win32ole'
            @browser = IEControl.new()

          when /linux|bsd|solaris|hpux|darwin/i
            begin
              require 'selenium-webdriver'
              puts "* AquireBrowser (Proxy: #{@proxy.server}:#{@proxy.port})"
              @browser = SeleniumRC.new(:firefox, :proxy => "#{@proxy.server}:#{@proxy.port}")
              puts @browser.class
            rescue LoadError
             # require 'net/telnet'
             # @browser = FFControl.new()
             puts "! Could not load Selenium Webdriver which is necessary for BrowserPreview Feature. Please install via:\n>gem install selenium-webdriver"
            end

          else # cygwin|java
            puts "!!! Could not aquire browser control for preview (unsupported OS) !!!"
          end
        elsif not @browser.ready?
          puts
          @browser.createBrowser
        end
      end

    end
  end
end
