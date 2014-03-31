# .
# session.rb
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
    class Proxy
      attr :login
      attr :name
      attr :host
      attr :port
      attr :login
      
      def unsetCredentials()
        @login = nil
      end

      def setCredentials(creds)
        @login = Hash.new
        @login.update creds
      end

      def has_login?
        return false if @login.nil?
        return true
      end

      def initialize(prefs)
        @login = nil
        @name = prefs[:name]
        @host = prefs[:host]
        @port = prefs[:port]

      end
    end

    class Session

include Watobo::Constants

      @@settings = Hash.new
      @@proxy = Hash.new

      @@session_lock = Mutex.new
      @@csrf_lock = Mutex.new

      @@login_mutex = Mutex.new
      @@login_cv = ConditionVariable.new
      @@login_in_progress = false
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listeners[event] ||= []
        @event_dispatcher_listeners[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
           puts "NOTIFY: #{self}(:#{event}) [#{@event_dispatcher_listeners[event].length}]" if $DEBUG
          @event_dispatcher_listeners[event].each do |m|           
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def runLogin(chat_list, prefs={})
        @@login_mutex.synchronize do
          begin
            @@login_in_progress = true
            login_prefs = Hash.new
            login_prefs.update prefs
            dummy = {:ignore_logout => true, :update_sids => true, :update_session => true, :update_contentlength => true}
            login_prefs.update dummy
            puts "! Start Login ..." if $DEBUG
            unless chat_list.empty?
              #  puts login_prefs.to_yaml
              chat_list.each do |chat|
                print "! LoginRequest: #{chat.id}" if $DEBUG
                test_req = chat.copyRequest
                request, response = doRequest(test_req, login_prefs)
              end
            else
              puts "! no login script configured !"
            end
          rescue => bang
            puts "!ERROR in runLogin"
            puts bang.backtrace if $DEBUG
          ensure
            @@login_in_progress = false
            @@login_cv.signal
            # exit
            #  print "L]"
          end
        end
      end

      #     def sessionSettings=(prefs)
      #       applySessionSettings(prefs)
      #     end

      def sessionSettings()
        @@settings
      end

      # sendHTTPRequest
      # returns Socket, ResponseHeader
      def sendHTTPRequest(request, prefs={})
#Watobo.print_debug("huhule", "#{prefs.to_yaml}", "gagagag")
        begin
          @lasterror = nil
          response_header = nil
          site = request.site
          proxy = getProxy(site)

          unless proxy.nil?
            host = proxy.host
            port = proxy.port
          else
            host = request.host
            port = request.port
          end
          # check if hostname is valid and can be resolved
          hostip = IPSocket.getaddress(host)
          # update current preferences, prefs given here are stronger then global settings!
          current_prefs = Hash.new
          [:update_session, :update_sids, :update_contentlength, :ssl_cipher, :www_auth, :client_certificates].each do |k|
            current_prefs[k] = prefs[k].nil? ? @session[k] : prefs[k]
          end

          updateSession(request) if current_prefs[:update_session] == true

          #---------------------------------------
          request.removeHeader("^Proxy-Connection") #if not use_proxy
          request.removeHeader("^Connection") #if not use_proxy
          request.removeHeader("^Accept-Encoding")
          # If-Modified-Since: Tue, 28 Oct 2008 11:06:43 GMT
          # If-None-Match: W/"3975-1225192003000"
          request.removeHeader("^If-")
          #  puts
          #  request.each do |line|
          #  puts line.unpack("H*")
          #end
          #puts
          if current_prefs[:update_contentlength] == true then
            request.fix_content_length()
          end

          #request.add_header("Via", "Watobo") if use_proxy
          #puts request
          # puts "=============="
        rescue SocketError
          puts "!!! unknown hostname #{host}"
          puts request.first
          return nil, "WATOBO: Could not resolve hostname #{host}", nil
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end

        begin
          unless proxy.nil?
            # connection requires proxy
            # puts "* use proxy #{proxy.name}"

            # check for regular proxy authentication
            if request.is_ssl?
              socket, response_header = sslProxyConnect(request, proxy, current_prefs)
              return socket, response_header, "WATOBO: could not connect to proxy #{proxy.name}:#{proxy.host}" if socket.nil?
              if current_prefs[:www_auth].has_key?(site)
                case current_prefs[:www_auth][site][:type]
                when AUTH_TYPE_NTLM
                  #  puts "* found NTLM credentials for site #{site}"
                  socket, response_header = wwwAuthNTLM(socket, request, current_prefs[:www_auth][site])

                  response_header.extend Watobo::Mixin::Parser::Url
                  response_header.extend Watobo::Mixin::Parser::Web10

                else
                  puts "* Unknown Authentication Type: #{current_prefs[:www_auth][site][:type]}"
                end
              else
                data = request.join + "\r\n"
                unless socket.nil?
                  socket.print data
                  response_header = readHTTPHeader(socket, current_prefs)
                end
              end
              return socket, request, response_header
            end
            #  puts "* doProxyRequest"
            socket, response_header = doProxyRequest(request, proxy, current_prefs)
            #   puts socket.class
            #   puts response_header.class

            return socket, request, response_header
          else
            # direct connection to host
            tcp_socket = nil
            #  timeout(6) do
            #puts "* no proxy - direct connection"
            tcp_socket = TCPSocket.new( host, port )
            tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
            tcp_socket.sync = true

            socket =  tcp_socket
            if request.is_ssl?
              ssl_prefs = {}
              ssl_prefs[:ssl_cipher] = current_prefs[:ssl_cipher] if current_prefs.has_key? :ssl_cipher
              if current_prefs.has_key? :client_certificates
                if current_prefs[:client_certificates].has_key? request.site
                  puts "* use ssl client certificate for site #{request.site}" if $DEBUG
                  ssl_prefs[:ssl_client_cert] = current_prefs[:client_certificates][request.site][:ssl_client_cert] 
                ssl_prefs[:ssl_client_key] = current_prefs[:client_certificates][request.site][:ssl_client_key]
                end
              end
              socket = sslConnect(tcp_socket, ssl_prefs)
            end
            #puts socket.class
            # remove URI before sending request but cache it for restoring request
            uri_cache = nil
            uri_cache = request.removeURI #if proxy.nil?

            # puts "========== Add Headers"
            request.addHeader("Connection", "Close") #if not use_proxy
            request.addHeader("Proxy-Connection", "Close") #if not use_proxy
            request.addHeader("Accept-Encoding", "None") #don't want encoding

            if current_prefs[:www_auth].has_key?(site)
              case current_prefs[:www_auth][site][:type]
              when AUTH_TYPE_NTLM
                # puts "* found NTLM credentials for site #{site}"
                socket, response_header = wwwAuthNTLM(socket, request, current_prefs[:www_auth][site])
                request.restoreURI(uri_cache)
                response_header.extend Watobo::Mixin::Parser::Url
                response_header.extend Watobo::Mixin::Parser::Web10

              else
                puts "* Unknown Authentication Type: #{current_prefs[:www_auth][site][:type]}"
              end
            else

              data = request.join + "\r\n"

              unless socket.nil?
                socket.print data
                response_header = readHTTPHeader(socket, current_prefs)
              end
              # RESTORE URI FOR HISTORY/LOG
              request.restoreURI(uri_cache)

            end
            return socket, request, response_header
          end

        rescue Errno::ECONNREFUSED
          response = error_response "connection refused (#{host}:#{port})"
          socket = nil
        rescue Errno::ECONNRESET
          response = error_response "connection reset (#{host}:#{port})"
          socket = nil
        rescue Errno::ECONNABORTED
          response = error_response "connection aborted (#{host}:#{port})"
          socket = nil
        rescue Errno::EHOSTUNREACH
          response = error_response "host unreachable (#{host}:#{port})"
          socket = nil
        rescue Timeout::Error
          #request = "WATOBO: TimeOut (#{host}:#{port})\n"
          response = error_response "TimeOut (#{host}:#{port})"
          socket = nil
        rescue Errno::ETIMEDOUT
          response = error_response "TimeOut (#{host}:#{port})"
          socket = nil
        rescue Errno::ENOTCONN
          puts "!!!ENOTCONN"
        rescue OpenSSL::SSL::SSLError
          response = error_response "SSL-Error", $!.backtrace.join
          socket = nil
        rescue => bang
          response = error_response "ERROR:", "#{bang}\n#{bang.backtrace}"
          socket = nil

          puts bang
          puts bang.backtrace if $DEBUG
        end
        
        return socket, request, response
      end

      def sidCache()
        #puts @project
        @session[:valid_sids]
      end

      def setSIDCache(new_cache = {} )
        @session[:valid_sids] = new_cache if new_cache.is_a? Hash
      end

      # +++ doRequest(request)  +++
      # + function:
      #
      def doRequest(request, opts={} )
        begin
          @session.update opts
          # puts "#[#{self.class}]" + @session[:csrf_requests].first.object_id.to_s
          unless @session[:csrf_requests].empty? or @session[:csrf_patterns].empty?
            csrf_cache = Hash.new
            @session[:csrf_requests].each do |req|
              copy = YAML.load(YAML.dump(req))
              copy.map!{|l|
                x = l.strip + "\r\n"
                x = l if l == copy.last
                x
              }
              # now extend the new request with the Watobo mixins
              copy.extend Watobo::Mixin::Parser::Url
              copy.extend Watobo::Mixin::Parser::Web10
              copy.extend Watobo::Mixin::Shaper::Web10

              # p copy.first

              updateCSRFToken(csrf_cache, copy)
              socket, csrf_request, csrf_response = sendHTTPRequest(copy, opts)
              puts "= Response Headers:"
              puts csrf_response
              puts "==="
              update_sids(csrf_request.host, csrf_response.headers)
              next if socket.nil?
              #  p "*"
              #    csrf_response = readHTTPHeader(socket)
              readHTTPBody(socket, csrf_response, csrf_request, opts)

              next if csrf_response.body.nil?
              update_sids(csrf_request.host, [csrf_response.body])

              updateCSRFCache(csrf_cache, csrf_request, [csrf_response.body]) if csrf_response.content_type =~ /text\//

              socket.close
            end
            #p @session[:csrf_requests].length
            updateCSRFToken(csrf_cache, request)
          end

          socket, request, response = sendHTTPRequest(request, opts)

          if socket.nil?
            return request, response
          end

          update_sids(request.host, response.headers) if @session[:update_sids] == true
          
          if @session[:follow_redirect]
 # puts response.status
  if response.status =~ /^302/
    response.extend Watobo::Mixin::Parser::Web10
    request.extend Watobo::Mixin::Shaper::Web10

    loc_header = response.headers("Location:").first
    new_location = loc_header.gsub(/^[^:]*:/,'').strip
    unless new_location =~ /^http/
      new_location = request.proto + "://" + request.site + "/" + request.dir + "/" + new_location.sub(/^[\.\/]*/,'')
    end
    
    notify(:follow_redirect, new_location)
    nr = YAML.load(YAML.dump(request))
    nr.extend Watobo::Mixin::Parser::Url
    nr.extend Watobo::Mixin::Parser::Web10
    nr.extend Watobo::Mixin::Shaper::Web10
    # create GET request for new location
    nr.replaceMethod("GET")
    nr.removeHeader("Content-Length")
    nr.removeBody()
    nr.replaceURL(new_location)

   # puts response
   # puts nr
   puts "send redirect request"
    socket, request, response = sendHTTPRequest(nr, opts)
    puts "= request"
    puts request
    puts "= response"
    puts response
    if socket.nil?
      #return nil, request
      return request, response
    end
  end
end

          readHTTPBody(socket, response, request, opts)

          unless response.body.nil?
            update_sids(request.host, [response.body]) if @session[:update_sids] == true and response.content_type =~ /text\//
          end

          socket.close

        rescue  => bang
          #  puts "! Error in doRequest"
          puts "! Module #{Module.nesting[0].name}"
          puts bang
          #  puts bang.backtrace if $DEBUG
          @lasterror = bang
          # raise
          # ensure
        end

        response.extend Watobo::Mixin::Parser::Web10
        return request, response
      end

      def addProxy(prefs=nil)

        #  puts "* add proxy"
        # puts prefs.to_yaml
        proxy = nil
        unless prefs.nil?
          proxy = Proxy.new(:name => prefs[:name], :host => prefs[:host], :port => prefs[:port])
          proxy.setCredentials(prefs[:credentials]) unless prefs[:credentials].nil?
          unless prefs[:site].nil?
            @@proxy[prefs[:site]] = proxy
            return
          end
        end

        @@proxy[:default] = proxy
      end

def get_settings
  @@settings
end

      def getProxy(site=nil)
        unless site.nil?
          return @@proxy[site] unless @@proxy[site].nil?
        end
        return @@proxy[:default]
      end

      #
      # INITIALIZE
      #
      # Possible preferences:
      # :proxy => '127.0.0.1:port'
      # :valid_sids => Hash.new,
      # :sid_patterns => [],
      # :logout_signatures => [],
      # :update_valid_sids => false,
      # :update_sids => false,
      # :update_contentlength => true
      def initialize(session_id, prefs={})
        @event_dispatcher_listeners = Hash.new
        #     @session = {}

        session = nil

        session = ( session_id.is_a? Fixnum ) ? session_id : session_id.object_id
        session = Digest::MD5.hexdigest(Time.now.to_f.to_s) if session_id.nil?

        unless @@settings.has_key? session
          @@settings[session] = {
            :valid_sids => Hash.new,
            :sid_patterns => [],
            # :valid_csrf_tokens => Hash.new,
            :csrf_patterns => [],
            :csrf_requests => [],
            :logout_signatures => [],
            :logout_content_types => Hash.new,
            :update_valid_sids => false,
            :update_sids => false,
            :update_session => true,
            :update_contentlength => true,
            :login_chats => [],
            :www_auth => Hash.new,
            :client_certificates => {},
            :proxy_auth => Hash.new
          }
        end
        @session = @@settings[session] # shortcut to settings
        @session.update prefs

        #  @valid_csrf_tokens = Hash.new

        addProxy( prefs[:proxy] ) if prefs.is_a? Hash and prefs[:proxy]

        @socket = nil

        @ctx = OpenSSL::SSL::SSLContext.new()
        @ctx.key = nil
        @ctx.cert = nil

        # TODO: Implement switches for URL-Encoding (http://www.blooberry.com/indexdot/html/topics/urlencoding.htm)
        # TODO: Implement switches for Following Redirects
        # TODO: Implement switches for Logging, Debugging, ...
      end

      def readHTTPBody(socket, response, request, prefs={})
        clen = response.content_length
        data = ""
        #   timeout(5) do
        begin
          if response.is_chunked?
            Watobo::HTTP.readChunkedBody(socket) { |c|
              data += c
            }
          elsif  clen > 0
            #  puts "* read #{clen} bytes for body"
            Watobo::HTTP.read_body(socket, :max_bytes => clen) { |c|
              data += c
              break if data.length == clen
            }
          else
            # puts "* no content-length information ... mmmmmpf"
            eofcount = 0
            Watobo::HTTP.read_body(socket) do |c|
              data += c
            end

          end
        rescue => e
          puts "! Could not read response"
          puts e
          # puts e.backtrace
        end
        # end

        response.push data
        unless prefs[:ignore_logout]==true  or @session[:logout_signatures].empty?
          notify(:logout, self) if loggedOut?(response)
        end

        update_sids(request.host, response) if prefs[:update_sids] == true

      end

      private

      #def doNtlmAuth(socket, request, ntlm_credentials)
      def wwwAuthNTLM(socket, request, ntlm_credentials)
        response_header = nil
        begin
          auth_request = Watobo::Utils::copyObject(request)
          auth_request.extend Watobo::Mixin::Parser::Url
          auth_request.extend Watobo::Mixin::Parser::Web10
          auth_request.extend Watobo::Mixin::Shaper::Web10

          ntlm_challenge = nil
          t1 = Net::NTLM::Message::Type1.new()
          msg = "NTLM " + t1.encode64

          auth_request.removeHeader("Connection")
          auth_request.removeHeader("Authorization")

          auth_request.addHeader("Authorization", msg)
          auth_request.addHeader("Connection", "Keep-Alive")

          #          puts "============= T1 ======================="
          #    puts auth_request
          data = auth_request.join + "\r\n"
          #puts "= REQUEST ="

          socket.print data
          #  puts "-----------------"
          response_header = []
          rcode = nil
          clen = nil
          ntlm_challenge = nil
          response_header = readHTTPHeader(socket)
          response_header.each do |line|
            if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
              rcode = $1.to_i
              rmsg = $2
            end
            if line =~ /^WWW-Authenticate: (NTLM) (.+)\r\n/
              ntlm_challenge = $2
            end
            if line =~ /^Content-Length: (\d{1,})\r\n/
              clen = $1.to_i
            end
            break if line.strip.empty?
          end
          #        puts "==================="

          #if rcode == 200 # Ok
          # puts "* seems request doesn't need authentication"
          #  return socket, response_header
          if rcode == 401 #Authentication Required
            puts "* got ntlm challenge: #{ntlm_challenge}" if $DEBUG
            return socket, response_header if ntlm_challenge.nil?
          else
            # puts "! arrgh .... :("
            # puts response_header
            return socket, response_header
          end

          # reading rest of response
          Watobo::HTTP.read_body(socket, :max_bytes => clen){ |d| }

          t2 = Net::NTLM::Message.decode64(ntlm_challenge)
          t3 = t2.response({:user => ntlm_credentials[:username],
            :password => ntlm_credentials[:password],
            :domain => ntlm_credentials[:domain]},
          {:workstation => ntlm_credentials[:workstation], :ntlmv2 => true})

          #     puts "* NTLM-Credentials: #{ntlm_credentials[:username]},#{ntlm_credentials[:password]}, #{ntlm_credentials[:domain]}, #{ntlm_credentials[:workstation]}"
          auth_request.removeHeader("Authorization")
          auth_request.removeHeader("Connection")

          auth_request.addHeader("Connection", "Close")

          msg = "NTLM " + t3.encode64
          auth_request.addHeader("Authorization", msg)
          #      puts "============= T3 ======================="

          data = auth_request.join + "\r\n"

          if $DEBUG
            puts "= NTLM Type 3 ="
                    puts data
                  end
          socket.print data

          response_header = []
          response_header = readHTTPHeader(socket)
          response_header.each do |line|

            if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
              rcode = $1.to_i
              rmsg = $2
            end
            break if line.strip.empty?
          end

          if rcode == 200 # Ok
            # puts "* authentication successfull [OK]"
          elsif rcode == 401 # Authentication Required
            # TODO: authorization didn't work -> do some notification
            # ...
            puts "* could not authenticate with the following credentials:"
            puts ntlm_credentials.to_yaml
          end

          return socket, response_header
        rescue => bang
          puts "!!! ERROR: in ntlm_auth"
          puts bang

          puts bang.backtrace if $DEBUG
          return nil, nil
        end
      end

      def sslConnect(tcp_socket, current_prefs = {} )
        begin
          #          @ctx = OpenSSL::SSL::SSLContext.new()
          #          @ctx.key = nil
          #          @ctx.cert = nil
          ctx = OpenSSL::SSL::SSLContext.new()
          ctx.ciphers = current_prefs[:ssl_cipher] if current_prefs.has_key? :ssl_cipher

          if current_prefs.has_key? :ssl_client_cert and current_prefs.has_key? :ssl_client_key
          
            ctx.cert = current_prefs[:ssl_client_cert]
            ctx.key = current_prefs[:ssl_client_key]
            if $DEBUG
                        puts "* using client certificates"
                        puts "= CERT ="
                       # puts @ctx.cert.methods.sort
              puts ctx.cert.display
              puts "---"
              p
                        puts "= KEY ="
                        puts ctx.key.display
                        puts "---"
                      end    
              

          end
          # @ctx.tmp_dh_callback = proc { |*args|
          #  OpenSSL::PKey::DH.new(128)
          #}

          socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)

          socket.connect
          socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          puts "* socket status: #{socket.state}" if $DEBUG
          return socket
        rescue => bang
          if current_prefs[:ssl_cipher].nil?
            puts "!sslConnect"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

      # SSLProxyConnect
      # return SSLSocket, ResponseHeader of ConnectionSetup
      def sslProxyConnect(orig_request, proxy, prefs)
        begin
          tcp_socket = nil
          response_header = []

          request = Watobo::Utils::copyObject(orig_request)
          request.extend Watobo::Mixin::Parser::Url
          request.extend Watobo::Mixin::Parser::Web10
          request.extend Watobo::Mixin::Shaper::Web10
          #  timeout(6) do

          tcp_socket = TCPSocket.new( proxy.host, proxy.port)
          tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          tcp_socket.sync = true
          #  end
          #  puts "* sslProxyConnect"
          #  puts "Host: #{request.host}"
          #  puts "Port: #{request.port}"
          # setup request
          dummy = "CONNECT #{request.host}:#{request.port} HTTP/1.0\r\n"
          request.shift
          request.unshift dummy

          request.removeHeader("Proxy-Connection")
          request.removeHeader("Connection")
          request.removeHeader("Content-Length")
          request.removeBody()
          request.addHeader("Proxy-Connection", "Keep-Alive")
          request.addHeader("Pragma", "no-cache")

          #  puts "=== sslProxyConnect ==="
          #  puts request

          if proxy.has_login?
            case proxy.login[:type]
            when AUTH_TYPE_NTLM

              ntlm_challenge = nil
              t1 = Net::NTLM::Message::Type1.new()
              msg = "NTLM " + t1.encode64
              request.addHeader("Proxy-Authorization", msg)

              # puts "============= T1 ======================="
              # puts request
              data = request.join + "\r\n"

              tcp_socket.print data
              #  puts "-----------------"
              while (line = tcp_socket.gets)
                response_header.push line
                # puts line
                if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
                  rcode = $1.to_i
                  rmsg = $2
                end
                if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
                  ntlm_challenge = $2
                end
                break if line.strip.empty?
              end

              Watobo::HTTP.read_body(tcp_socket) { |d|
                # puts d
              }

              if rcode == 200 # Ok
                puts "* seems proxy doesn't require authentication"
                socket = sslConnect(tcp_socket, prefs)
                return socket, response_header
              end

              return socket, response_header if ntlm_challenge.nil? or ntlm_challenge == ""

              t2 = Net::NTLM::Message.decode64(ntlm_challenge)
              t3 = t2.response( { :user => proxy.login[:username],
                :password => proxy.login[:password],
                :domain => proxy.login[:domain] },
              { :workstation => proxy.login[:workstation], :ntlmv2 => true } )
              request.removeHeader("Proxy-Authorization")

              msg = "NTLM " + t3.encode64
              request.addHeader("Proxy-Authorization", msg)
              # puts "============= T3 ======================="
              #  puts request
              data = request.join + "\r\n"

              tcp_socket.print data
              #  puts "-----------------"

              response_header = []
              rcode = 0
              response_header = readHTTPHeader(tcp_socket)
              rcode = response_header.status
              if rcode =~/^200/ # Ok
                puts "* proxy authentication successfull"
              elsif rcode =~ /^407/ # ProxyAuthentication Required
                # if rcode is still 407 authentication didn't work -> break
                return nil
              else
                puts "! check proxy connection [FALSE]"
                puts ">  #{rcode} #{rmsg} <"
              end

              socket = sslConnect(tcp_socket, prefs)
              return socket, response_header
            end
          end # END OF PROXY AUTH

          # Start ProxyConnect Without Authentication
          data = request.join + "\r\n"
          tcp_socket.print data
          # puts "-----------------"

          response_header = []
          response_header = readHTTPHeader(tcp_socket)
          rcode = response_header.status
          if rcode =~ /^200/ # Ok
            # puts "* proxy connection successfull"
          elsif rcode =~ /^407/ # ProxyAuthentication Required
            # if rcode is still 407 authentication didn't work -> break

          else
            puts "! check proxy connection [FALSE]"
            puts ">  #{rcode} #{rmsg} <"
          end

          socket = sslConnect(tcp_socket, prefs)
          return socket, response_header
        rescue => bang
          puts bang
          return nil, bang
        end
        # return nil, nil
      end

      # proxyAuthNTLM
      # returns: ResponseHeaders
      def proxyAuthNTLM(tcp_socket, orig_request, credentials)

        request = Watobo::Utils::copyObject(orig_request)
        request.extend Watobo::Mixin::Parser::Url
        request.extend Watobo::Mixin::Parser::Web10
        request.extend Watobo::Mixin::Shaper::Web10

        request.removeHeader("Proxy-Authorization")
        request.removeHeader("Proxy-Connection")

        response_header = []

        ntlm_challenge = nil
        t1 = Net::NTLM::Message::Type1.new()
        msg = "NTLM " + t1.encode64

        request.addHeader("Proxy-Authorization", msg)
        request.addHeader("Proxy-Connection", "Keep-Alive")

        #   puts "============= T1 ======================="
        #    puts auth_request
        data = request.join + "\r\n"

        tcp_socket.print data
        #  puts "-----------------"
        response_header = readHTTPHeader(tcp_socket)
        rcode = nil
        rmsg = nil
        ntlm_challenge = nil
        clen = 0
        response_header.each do |line|
          # puts line
          if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
            rcode = $1.to_i
            rmsg = $2
          end
          if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
            ntlm_challenge = $2
          end
          if line =~ /^Content-Length: (\d{1,})\r\n/
            clen = $1.to_i
          end
          break if line.strip.empty?
        end

        #puts "* reading #{clen} bytes"

        if rcode == 407 # ProxyAuthentication Required
          return response_header if ntlm_challenge.nil? or ntlm_challenge == ""
        else
          puts "* no proxy authentication required!"
          return response_header
        end

        Watobo::HTTP.read_body(tcp_socket, :max_bytes => clen){ |d|
          #puts d
        }

        t2 = Net::NTLM::Message.decode64(ntlm_challenge)
        t3 = t2.response({:user => credentials[:username], :password => credentials[:password], :workstation => credentials[:workstation], :domain => credentials[:domain]}, {:ntlmv2 => true})
        request.removeHeader("Proxy-Authorization")
        #  request.removeHeader("Proxy-Connection")

        #  request.addHeader("Proxy-Connection", "Close")
        #  request.addHeader("Pragma", "no-cache")
        msg = "NTLM " + t3.encode64
        request.addHeader("Proxy-Authorization", msg)
        # puts "============= T3 ======================="
        # puts request
        # puts "------------------------"
        data = request.join + "\r\n"
        tcp_socket.print data

        response_header = readHTTPHeader(tcp_socket)
        response_header.each do |line|
          #  puts line
          if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
            rcode = $1.to_i
            rmsg = $2
          end
          if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
            ntlm_challenge = $2
          end
          if line =~ /^Content-Length: (\d{1,})\r\n/
            clen = $1.to_i
          end
          break if line.strip.empty?
        end
        #  Watobo::HTTP.read_body(tcp_socket, :max_bytes => clen){ |d|
        #puts d
        #  }
        return response_header
      end

      #
      # doProxyAuth
      #
      def doProxyAuth(tcp_socket, orig_request, credentials)
        response_headers = nil
        case credentials[:type]
        when AUTH_TYPE_NTLM
          return proxyAuthNTLM(tcp_socket, orig_request, credentials)

        end # END OF NTLM

      end

      ##################################################
      #    doProxyRequest
      ################################################
      def doProxyRequest(request, proxy, prefs={})

        begin
          tcp_socket = nil
          site = request.site

          auth_request = Watobo::Utils::copyObject(request)
          auth_request.extend Watobo::Mixin::Parser::Url
          auth_request.extend Watobo::Mixin::Parser::Web10
          auth_request.extend Watobo::Mixin::Shaper::Web10
          #  timeout(6) do

          tcp_socket = TCPSocket.new( proxy.host, proxy.port)
          tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          tcp_socket.sync = true
          #  end

          auth_request.removeHeader("Proxy-Connection")
          auth_request.removeHeader("Connection")

          auth_request.addHeader("Pragma", "no-cache")

          if proxy.has_login?
            request_header = doProxyAuth(tcp_socket, auth_request, proxy.login)
            # puts "* got request_header from doProxy Auth"
            # puts request_header.class
            return tcp_socket, request_header
          end

          if prefs[:www_auth].has_key?(site)
            case prefs[:www_auth][site][:type]
            when AUTH_TYPE_NTLM
              # puts "* found NTLM credentials for site #{site}"
              socket, response_header = wwwAuthNTLM(tcp_socket, request, prefs[:www_auth][site])

              response_header.extend Watobo::Mixin::Parser::Url
              response_header.extend Watobo::Mixin::Parser::Web10
              return socket, response_header
            else
              puts "* Unknown Authentication Type: #{prefs[:www_auth][site][:type]}"
            end
          else
            data = auth_request.join + "\r\n"

            tcp_socket.print data

            request_header = readHTTPHeader(tcp_socket)
            return tcp_socket, request_header
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG

        end
        return nil
      end

      def loggedOut?(response, prefs={})
        begin
          return false if @session[:logout_signatures].empty?
          response.each do |line|
            @session[:logout_signatures].each do |p|
              #     puts "!!!*LOGOUT*!!!" if line =~ /#{p}/
              return true if line =~ /#{p}/
            end
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return false
      end

      def error_response(msg, comment=nil)
        er = []
      er << "HTTP/1.1 504 Gateway Timeout\r\n"
      er << "WATOBO: #{msg}\r\n"
      er << "Content-Length: 0\r\n"
      er << "Connection: close\r\n"
      er << "\r\n"
      er << "<H1>#{msg}</H1>"
      er << "<H2>#{comment}</H2>" unless comment.nil?
       er.extend Watobo::Mixin::Parser::Url
        er.extend Watobo::Mixin::Parser::Web10
        er.extend Watobo::Mixin::Shaper::Web10
        er.fix_content_length
        er
      end
      
      def readHTTPHeader(socket, prefs={})
        header = []
        msg = nil
        begin
          Watobo::HTTP.read_header(socket) do |line|
            # puts line.unpack("H*")
            header.push line
          end
          rescue Errno::ECONNRESET
            msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Connection Reset By Peer</body></html>"           
          rescue Timeout::Error
            msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Timeout</body></html>"
        rescue => bang
          puts "!ERROR: read_header"
          return nil
        end
         
         header = [ "HTTP/1.1 200 OK\r\n", "Server: WATOBO\r\n", "Content-Length: #{msg.length.to_i}\r\n", "Content-Type: text/html\r\n", "\r\n", "#{msg}" ] unless msg.nil?

        header.extend Watobo::Mixin::Parser::Url
        header.extend Watobo::Mixin::Parser::Web10
        #  update_sids(header)

        #  update_sids(request.site, response) if prefs[:update_sids] == true

        unless prefs[:ignore_logout]==true or @session[:logout_signatures].empty?
           notify(:logout, self) if loggedOut?(header)
        end

        return header
      end

      #     def read_response(socket)

      #       return response
      #    end

      def update_sids(host, response)
        #   p "* update sids"
        Thread.new{
          begin
            #site = request.site
            @@session_lock.synchronize do
              response.each do |line|
                # puts line
                @session[:sid_patterns].each do |pat|
                  if line =~ /#{pat}/i then
                    sid_key = Regexp.quote($1.upcase)
                    sid_value = $2
                    #print "U"
                    #   puts "GOT NEW SID (#{sid_key}): #{sid_value}"
                    @session[:valid_sids][host] = Hash.new if @session[:valid_sids][host].nil?
                    @session[:valid_sids][host][sid_key] = sid_value
                  end
                end

              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG

          end
        }
      end

      def updateCSRFCache(csrf_cache, request, response)
         puts "=UPDATE CSRF CACHE" if $DEBUG
        # Thread.new{
        begin
          #   site = request.site
          @@csrf_lock.synchronize do
            response.each do |line|
              # puts line
              @session[:csrf_patterns].each do |pat|
                puts pat if $DEBUG
                if line =~ /#{pat}/i then
                  token_key = Regexp.quote($1.upcase)
                  token_value = $2
                  #print "U"
                    puts "GOT NEW TOKEN (#{token_key}): #{token_value}" if $DEBUG
                  #   @session[:valid_csrf_tokens][site] = Hash.new if @session[:valid_csrf_tokens][site].nil?
                  #   @session[:valid_csrf_tokens][site][token_key] = token_value
                  csrf_cache[token_key] = token_value
                end
              end

            end
          end
        rescue => bang
          puts bang
          if $DEBUG
          puts bang.backtrace 
          puts "= Request"
          puts request 
          puts "= Response"
          puts response
          puts "==="
          end

        end
        # }
      end

      def closeSocket(socket)
        #puts socket.class
        begin
          #puts socket.class
          #if socket.class.to_s =~ /SSLSocket/
          if socket.is_a? OpenSSL::SSL::SSLSocket
            socket.io.shutdown(2)
          else
            socket.shutdown(2)
          end
          socket.close
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def updateSessionSettings(settings={})
        [
          :ssl_client_cert,
          :ssl_client_key,
          :ssl_client_pass,
          :csrf_requests,
          :valid_sids,
          :sid_patterns,
          :logout_signatures,
          :logout_content_types,
          :update_valid_sids,
          :update_sids,
          :update_session,
          :update_contentlength,
          :login_chats,
          :follow_redirect
        ].each do |k|
          @session[k] = settings[k] if settings.has_key? k
        end
      end

      def updateSession(request)
        @@session_lock.synchronize do
          if @session[:valid_sids].has_key?(request.host)
            # puts "* found sid for site: #{request.site}"
            request.map!{ |line|
              res = line
              @session[:sid_patterns].each do |pat|
                begin
                  if line =~ /#{pat}/i then
                    next if $~.length < 3
                    sid_key = Regexp.quote($1.upcase)
                    old_value = $2

                    if @session[:valid_sids][request.host].has_key?(sid_key) then
                      if not old_value =~ /#{@session[:valid_sids][request.host][sid_key]}/ then # sid value has changed and needs update
                        Watobo.print_debug("update session", "#{old_value} - #{@session[:valid_sids][request.host][sid_key]}") if $DEBUG
                        
                        res = line.gsub!(/#{Regexp.quote(old_value)}/, @session[:valid_sids][request.host][sid_key])
                        
                        if not res then puts "!!!could not update sid (#{sid_key})"; end

                      end
                    end
                  end
                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                  # puts @session.to_yaml
                end
              end
              res
            }
          end
        end
      end

      def updateCSRFToken(csrf_cache, request)
        # puts "=UPDATE CSRF TOKEN"
        # @session[:valid_csrf_tokens].to_yaml
        # puts request if request.site.nil?
        # puts "= = = = = = "
        @@csrf_lock.synchronize do
          #  if @session[:valid_csrf_tokens].has_key?(request.site)
          #    puts "* found token for site: #{request.site}"

          request.map!{ |line|
            res = line
            @session[:csrf_patterns].each do |pat|
              begin
                if line =~ /#{pat}/i then
                  key = Regexp.quote($1.upcase)
                  old_value = $2
                  # if @session[:valid_csrf_tokens][request.site].has_key?(key) then
                  if csrf_cache.has_key?(key) then
                    res = line.gsub!(/#{Regexp.quote(old_value)}/, csrf_cache[key])
                    if res.nil? then
                      res = line
                      puts "!!!could not update token (#{key})"
                    end
                    #     puts "->#{line}"

                    #end
                  end
                end
              rescue => bang
                puts bang
                puts bang.backtrace if $DEBUG
                # puts @session.to_yaml
              end
            end
            res
          }
        end
        # end
      end

      # this function updates specific patterns of a request, e.g. CSRF Tokens
      # Parameters:
      # request - the request which has to be updated
      # cache - the value store of already collected key-value-pairs
      # patterns - pattern expressions, similar to session-id-patterns, e.g.  /name="(sessid)" value="([0-9a-zA-Z!-]*)"/
      def updateRequestPattern(request, cache, patterns)

        request.map!{ |line|
          res = line
          patterns.each do |pat|
            begin
              if line =~ /#{pat}/i then
                pattern_key = Regexp.quote($1.upcase)
                old_value = Regexp.quote($2)
                if cache.has_key?(sid_key) then
                  if not old_value =~ /#{cache[sid_key]}/ then # sid value has changed and needs update
                    #      print "S"
                    #    puts "+ update sid #{sid_key}"
                    #    puts "-OLD: #{old_value}"
                    #    puts "-NEW: #{@session[:valid_sids][request.site][sid_key]}"

                    #      puts "---"
                    # dummy = Regexp.quote(old_value)
                    res = line.gsub!(/#{old_value}/, cache[sid_key])
                    if not res then puts "!!!could not update sid (#{sid_key})"; end
                    #     puts "->#{line}"
                  end
                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              # puts @session.to_yaml
            end
          end
          res
        }
      end

      def applySessionSettings(prefs)
        [ :update_valid_sids, :update_session, :update_contentlength, :valid_sids, :sid_patterns, :logout_signatures ].each do |v|
          @@settings[v] = prefs[v] if prefs[v]
        end
      end

    end
end
