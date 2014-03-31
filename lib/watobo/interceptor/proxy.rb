# .
# proxy.rb
# 
# Copyright 2013 by siberas, http://www.siberas.de
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
# @private 
module Watobo#:nodoc: all
  module Interceptor
    #
    class Proxy

      include Watobo::Constants

      attr :port

      attr_accessor :proxy_mode

      attr_accessor :contentLength
      attr_accessor :contentTypes
      attr_accessor :target
      attr :www_auth
      attr_accessor :client_certificates
      
      def self.transparent?
        return true if ( Watobo::Conf::Interceptor.proxy_mode & Watobo::Interceptor::MODE_TRANSPARENT ) > 0
        return false
      end
      
      def server
        @bind_addr
      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def getResponseFilter()
        YAML.load(YAML.dump(@response_filter_settings))
      end

      def getRequestFilter()
        YAML.load(YAML.dump(@request_filter_settings))
      end

      def setResponseFilter(new_settings)
        @response_filter_settings.update new_settings unless new_settings.nil?
      end

      def setRequestFilter(new_settings)
        @request_filter_settings.update new_settings unless new_settings.nil?
      # puts @request_filter_settings.to_yaml
      end

      def clear_request_carvers
        @request_carvers.clear unless @request_carvers.nil?

      end

      def clear_response_carvers
        @response_carvers.clear unless @response_carvers.nil?
      end

      def addPreview(response)
        preview_id = Digest::MD5.hexdigest(response.join)
        @preview[preview_id] = response
        return preview_id
      end

      def stop()
        begin
          puts "[#{self.class}] stop"
          if @t_server.respond_to? :status
            puts @t_server.status
          Thread.kill @t_server
          @intercept_srv.close
          end
        rescue IOError => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      #
      # R U N
      #

      def self.start(settings = {})
        proxy = Proxy.new(settings)
        proxy.start
        proxy
      end

      def start()

        if transparent?
          Watobo::Interceptor::Transparent.start
        end

        begin
          @intercept_srv = TCPServer.new(@bind_addr, @port)
          @intercept_srv.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1 )

        rescue => bang
          puts "\n!!!Could not start InterceptProxy"
          puts bang
          return nil
        end
        puts "\n* Intercepor started on #{@bind_addr}:#{@port}"
        session_list = []
        puts "!!! TRANSPARENT MODE ENABLED !!!" if transparent?

        @t_server = Thread.new(@intercept_srv) { |server|
        while (new_session = server.accept)
          #  new_session.sync = true
          Thread.new(new_session) { |session|

            c_sock = Watobo::HTTPSocket::ClientSocket.connect(session)
            Thread.exit if c_sock.nil?
            loop do
            flags = []
            begin

              request = c_sock.request

              if request.nil? or request.empty? then
                c_sock.close
                Thread.exit
              end
              puts "*[I] #{request.url}"

            rescue => bang
              puts "!!! Error reading client request "
              puts bang
              puts bang.backtrace
              puts request.class
             # puts request
             closeSocket(c_sock)
             Thread.exit
            #break
            end

            # check if preview is requested
            if request.host =='watobo.localhost' or request.first =~ /WATOBOPreview/ then
              if request.first =~ /WATOBOPreview=([0-9a-zA-Z]*)/ then

                puts "* preview requested ..."
                puts request.url

                hashid = $1
                response = @preview[hashid]

                if response then
                  c_sock.write response.join
                  closeSocket(c_sock)
                end
              end
            #next
            Thread.current.exit
            end

            request_intercepted = false
            # no preview, check if interception request is turned on
            if Watobo::Interceptor.rewrite_requests? then
              Interceptor::RequestCarver.shape(request, flags)
              puts "FLAGS >>"
              puts flags
            end

            if @target and Watobo::Interceptor.intercept_requests? then
              if matchRequestFilter(request)
                @awaiting_requests += 1
                request_intercepted = true

                if @target.respond_to? :addRequest
                  #  puts "*INTERCEPT REQUEST"
                  #  puts @target
                  #notify(:modify_request, request, Thread.current)
                  Watobo.print_debug "send request to target"
                  @target.addRequest(request, Thread.current)
                  puts "* stopping thread: #{Thread.current} ..."
                  Thread.stop
                  puts "* released thread: #{Thread.current}"
                else
                  p "! no target for editing request"
                end
              @awaiting_requests -= 1
              end
            end
            # req, resp = @sender.sendRequest(request, :update_sids => false, :update_session => false, :update_contentlength => true)

            #p "getHTTPHeader"
            #s_sock, req, resp = @sender.getHTTPHeader(request, :update_sids => true, :update_session => false, :update_contentlength => true)
            begin

            s_sock, req, resp = @sender.sendHTTPRequest(request, :update_sids => true, :update_session => false, :update_contentlength => true, :www_auth => @www_auth, :client_certificates => @client_certificates)
            if s_sock.nil? then
              puts request if $DEBUG
              c_sock.write resp.join unless resp.nil?
              c_sock.close
            #Thread.kill Thread.current
            Thread.exit
            next
            end

            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              c_sock.close
              #Thread.kill Thread.current
              Thread.exit
            end

            # check if response should be passed throug
            #Thread.current.exit if isPassThrough?(req, resp, s_sock, c_sock)
            #p "no pass-through"

            begin
            # puts "* got response status: #{resp.status}"
              missing_credentials = false
              rs = resp.status
              if rs =~ /^(401|407)/ then
                missing_credentials = true

                auth_type = AUTH_TYPE_NONE
                resp.each do |rl|
                  if rl =~ /^(Proxy|WWW)-Authenticate: Basic/i
                    auth_type = AUTH_TYPE_BASIC
                  break
                  elsif rl =~ /^(Proxy|WWW)-Authenticate: NTLM/i
                    auth_type = AUTH_TYPE_NTLM
                  break
                  end
                end
                # when auth type not basic assume it's ntlm -> ntlm credentials must be set in watobo
                unless auth_type == AUTH_TYPE_NONE
                  if auth_type == AUTH_TYPE_NTLM
                    if rs =~ /^401/ then
                      resp.push "WATOBO: Server requires (NTLM) authorization, please set WWW_Auth Credentials!"
                      resp.shift
                      resp.unshift "HTTP/1.1 200 OK\r\n"
                    else
                      resp.push "WATOBO: Proxy requires (NTLM) authorization, please set Proxy Credentials!"
                      resp.shift
                      resp.unshift "HTTP/1.1 200 OK\r\n"
                    end
                  end
                else

                  resp.push "WATOBO: Unknown authorization type.<br><br>\r\n" + resp.join("<br>\r\n")
                  resp.shift
                  resp.unshift "HTTP/1.1 200 OK\r\n"
                resp.fix_content_length

                end
              else
                # don't try to read body if request method is HEAD
                unless req.method =~ /^head/i
                @sender.readHTTPBody(s_sock, resp, req, :update_sids => true)
                 end
              end
            rescue => bang
              puts "!!! could not send request !!!"
              puts bang
              puts bang.backtrace if $DEBUG
            #  puts "* Error sending request"
            end

            begin
              # Watobo::Response.create resp
              resp = Watobo::Response.new resp
             # puts "* unchunk response ..."
              resp.unchunk
              # puts "* unzip response ..."
              resp.unzip

              if Watobo::Interceptor.rewrite_responses? then
                 Interceptor::ResponseCarver.shape(resp, flags)
              end

              if @target and Watobo::Interceptor.intercept_responses? then
                if matchResponseFilter(resp)
                  #  if resp.content_type =~ /text/ or resp.content_type =~ /application\/javascript/ then
                  if @target.respond_to? :modifyResponse
                    @target.modifyResponse(resp, Thread.current)
                    Thread.stop
                  else
                    p "! no target for editing response"
                  end
                end
              end

             # puts ">> SEND TO CLIENT"
             if missing_credentials
               resp.set_header("Connection", "close")
                c_sock.write resp.join
                c_sock.close
             else
              c_sock.write resp.join
              end
             # puts resp.join
             # puts "-----"
             # closeSocket(c_sock)

            rescue Errno::ECONNRESET
              print "x"
              #  puts "!!! ERROR (Reset): reading body"
              #  puts "* last data seen on socket: #{buf}"
              #return
            rescue Errno::ECONNABORTED
              print "x"
              #return
            rescue => bang
              puts "!!! Error (???) in Client Communication:"
              puts bang
              puts bang.class
              puts bang.backtrace #if $DEBUG
            #return
            end

            chat = Chat.new(request.copy, resp.copy, :source => CHAT_SOURCE_INTERCEPT)
           # notify(:new_interception, chat)
           Watobo::Chats.add chat
           Thread.current.exit if missing_credentials
end
          }

        end
      }
      end

      def refresh_www_auth
        @www_auth = Watobo::Conf::Scanner.www_auth
      end

      def initialize(settings=nil)
        @event_dispatcher_listeners = Hash.new
        begin

          puts
          puts "=== Initialize Interceptor/Proxy ==="
          #   @project = project
          #   @settings = settings
          # @port = @settings[:intercept_port]
          #   puts settings.to_yaml

          #  @proxy_mode = Watobo::Interceptor.proxy_mode

          #Watobo::Interceptor.proxy_mode = INTERCEPT_NONE

          init_instance_vars

          @awaiting_requests = 0
          @awaiting_responses = 0

          @request_filter_settings = {
          :site_in_scope => false,
          :method_filter => '(get|post|put)',
          :negate_method_filter => false,
          :negate_url_filter => false,
          :url_filter => '',
          :file_type_filter => '(jpg|gif|png|jpeg|bmp)',
          :negate_file_type_filter => true,

          :parms_filter => '',
          :negate_parms_filter => false
          #:regex_location => 0, # TODO: HEADER_LOCATION, BODY_LOCATION, ALL

        }

          @response_filter_settings = {
          :content_type_filter => '(text|script)',
          :negate_content_type_filter => false,
          :response_code_filter => '2\d{2}',
          :negate_response_code_filter => false,
          :request_intercepted => false,
          :content_printable => true,
          :enable_printable_check => false
        }

          @preview = Hash.new
          @preview['ProxyTest'] = ["HTTP/1.0 200 OK\r\nServer: Watobo-Interceptor\r\nConnection: close\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n<html><body>PROXY_OK</body></html>"]

          # p @settings[:certificate_path]
          # p @settings[:cert_file]
          # p @settings[:key_file]
          # crt_path = Watobo::Conf::Interceptor.certificate_path
          # crt_file = Watobo::Conf::Interceptor.cert_file
          # key_file = Watobo::Conf::Interceptor.key_file
          # dh_key_file = Watobo::Conf::Interceptor.dh_key_file

          # crt_filename = File.join(Watobo.base_directory, crt_path, crt_file)
          # key_filename = File.join(Watobo.base_directory, crt_path, key_file)

          #  @ctx = OpenSSL::SSL::SSLContext.new('SSLv23_server')
          # @cert = OpenSSL::X509::Certificate.new(File.read(crt_filename))
          # @key = OpenSSL::PKey::RSA.new(File.read(key_filename))

          #@dh_key = OpenSSL::PKey::DH.new(File.read(dh_filename))
          @dh_key = Watobo::CA.dh_key
          #  @ctx.ciphers = nil # ['TLSv1/SSLv3', 56, 56 ]

        rescue => bang
          puts "!!!could not read certificate files:"
          puts bang
          puts bang.backtrace if $DEBUG
        end

      end

      private

      def init_instance_vars
        @www_auth = Watobo::Conf::Scanner.www_auth
        @fake_certs = {}
        @client_certificates = {}
        @target = nil
        @sender = Watobo::Session.new(@target)

        @bind_addr = Watobo::Conf::Interceptor.bind_addr
        puts "> Server: #{@bind_addr}"
        @port = Watobo::Conf::Interceptor.port
        puts "> Port: #{@port}"
        @proxy_mode = Watobo::Conf::Interceptor.proxy_mode

        pt = Watobo::Conf::Interceptor.pass_through
        @contentLength = pt[:content_length]
        puts "> PT-ContentLength: #{@contentLength}"
        @contentTypes = pt[:content_types]
        puts "> PT-ContentTypes: #{@contentTypes}"
      end

      #
      #
      # matchContentType(content_type)
      #
      #
      def matchContentType?(content_type)
        @contentTypes.each do |p|
          return true if content_type =~ /#{p}/
        end
        return false
      end

      #
      #
      # matchRequestFilter(request)
      #
      #
      def matchRequestFilter(request)
        match_url = true
        # puts @request_filter_settings.to_yaml
        url_filter = @request_filter_settings[:url_filter]
        if url_filter != ''
          match_url = false
          if request.url.to_s =~ /#{url_filter}/i
          match_url = true
          end
          if @request_filter_settings[:negate_url_filter] == true
          match_url = ( match_url == true ) ? false : true
          end
        end

        return false if match_url == false

        match_method = true
        method_filter = @request_filter_settings[:method_filter]
        if method_filter != ''
          match_method = false
          if request.method =~ /#{method_filter}/i
          match_method = true
          end

          if @request_filter_settings[:negate_method_filter] == true
          match_method = ( match_method == true ) ? false : true
          end
        end

        return false if match_method == false

        match_ftype = true
        ftype_filter = @request_filter_settings[:file_type_filter]
        if ftype_filter != ''
          match_ftype = false
          if request.doctype != '' and request.doctype =~ /#{ftype_filter}/i
          match_ftype = true
          end
          if @request_filter_settings[:negate_file_type_filter] == true
          match_ftype = ( match_ftype == true ) ? false : true
          end
        end
        return false if match_ftype == false

        match_parms = true
        parms_filter = @request_filter_settings[:parms_filter]
        if parms_filter != ''
          puts "!PARMS FILTER: #{parms_filter}"
          match_parms = false
          puts request.parms
          match_parms = request.parms.find {|x| x =~ /#{parms_filter}/ }
          match_parms = ( match_parms.nil? ) ? false : true
          if @request_filter_settings[:negate_parms_filter] == true
          match_parms = ( match_parms == true ) ? false : true
          end
        end
        return false if match_parms == false

        true
      end

      #
      #
      # matchResponseFilter(response)
      #
      #

      def matchResponseFilter(response)
        match_ctype = true
        ct_filter = @response_filter_settings[:content_type_filter]
        unless ct_filter.empty?
          match_ctype = false
          negate = @response_filter_settings[:negate_content_type_filter]
          if response.content_type =~ /#{ct_filter}/
          match_ctype = true

          end
          if negate == true
          match_ctype = ( match_ctype == true ) ? false : true
          end
        end
        return false if match_ctype == false
        puts "* pass ctype filter"
        match_rcode = true
        rcode_filter = @response_filter_settings[:response_code_filter]
        negate = @response_filter_settings[:negate_response_code_filter]
        unless rcode_filter.empty?
          match_rcode = false
          puts rcode_filter
          puts response.responseCode
          if response.responseCode =~ /#{rcode_filter}/
          match_rcode = true
          end
          if negate == true
          match_rcode = ( match_rcode == true ) ? false : true
          end
        end
        return false if match_rcode == false
        puts "* pass rcode filter"
        true
      end

      #
      #
      # pass_through(server, client, maxbytes)
      #
      #
      def pass_through(server, client, maxbytes = 0)
        buf = ''
        print "[~"
        bytes_read = 0
        while buf
          begin
          #timeout(2) do
            buf = nil
            buf = server.readpartial(2048)
            #end
          rescue EOFError
          #client.write buf if buf
          #print "~]"
            return if buf.nil?
          rescue Errno::ECONNRESET
          # puts "!!! ERROR (Reset): reading body"
          # puts "* last data seen on socket: #{buf}"
            print "R"
            return if buf.nil?
          rescue Timeout::Error
          #puts "!!! ERROR (Timeout): reading body"
          #puts "* last data seen on socket:"
          #client.write buf if buf
            print "T"
            return if buf.nil?
          rescue => bang
            puts "!!! could not read body !!!"
            puts bang
            puts bang.class
            puts bang.backtrace if $DEBUG
          # puts "* last data seen on socket:"
          # print "~]"
          #client.write buf if buf
          return
          end

          begin
            return if buf.nil?
            print "~"
            client.write buf
            bytes_read += buf.length
            # puts "##{bytes_read} of #{maxbytes}"
            if maxbytes > 0 and bytes_read >= maxbytes
              print "~]"
            return
            end

          rescue Errno::ECONNRESET
            print "~x]"
            #  puts "!!! ERROR (Reset): reading body"
            #  puts "* last data seen on socket: #{buf}"
            return
          rescue Errno::ECONNABORTED
            print "~x]"
            return
          rescue Errno::EPIPE
            print "~x]"
            return
          rescue => bang
            puts "!!! client communication broken !!!"
            puts bang
            puts bang.class
            puts bang.backtrace if $DEBUG
          return
          end
        end
      end

      def transparent?
        return true if ( @proxy_mode & Watobo::Interceptor::MODE_TRANSPARENT ) > 0
        return false
      end

      def read_request(socket)
        request = []
        # read http header lines
        session = socket

        ra = socket.remote_address
        cport = ra.ip_port
        caddr = ra.ip_address

        if transparent?

          ci = @connections.info({ 'host' => caddr, 'port' => cport } )
          unless ci['target'].empty? or ci['cn'].empty?
            puts "SSL-REQUEST FROM #{caddr}:#{cport}"

            ctx = Watobo::CertStore.acquire_ssl_ctx ci['target'], ci['cn']

            begin
              ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
              ssl_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
              # ssl_socket.sync_close = true
              ssl_socket.sync = true
              # puts ssl_socket.methods.sort
              session = ssl_socket.accept
            rescue OpenSSL::SSL::SSLError => e
              puts ">> SSLError"
              puts e
              return nil, session
            rescue => bang
              puts bang
              puts bang.backtrace
              return nil, session
            end
          else
            puts ci['host']
            puts ci['cn']
          end
        end

        Watobo::HTTPSocket.read_header(session) do |line|
        # puts line
          request.push line
        end

        if transparent?
          #puts "> get hostname ..."
          thn = nil
          request.each do |l|
            if l =~ /^Host: (.*)/
            thn = $1.strip
            #   puts ">> #{thn}"
            end
          end
          # puts session.class
          # puts "* fix request line ..."
          # puts request.first
          # puts ">>"
          if session.is_a? OpenSSL::SSL::SSLSocket
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i,"\\1 https://#{thn}\\2 \\3")
          else
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i,"\\1 http://#{thn}\\2 \\3")
          end
        #puts request.first
        end

        if request.first =~ /^CONNECT (.*):(\d{1,5}) HTTP\/1\./ then
          target = $1
          tport = $2
          # puts request.first
          #  print "\n* CONNECT: #{method} #{target} on port #{tport}\n"

          socket.print "HTTP/1.0 200 Connection established\r\n" +
          "Proxy-connection: Keep-alive\r\n" +
          "Proxy-agent: WATOBO-Proxy/1.1\r\n" +
          "\r\n"
          bscount = 0 # bad handshake counter
          #  puts "* wait for ssl handshake ..."
          begin
            dst = "#{target}:#{tport}"
            unless @fake_certs.has_key? dst
              puts "NEW CERTIFICATE FOR >> #{dst} <<"
              cn = Watobo::HTTPSocket.get_ssl_cert_cn(target, tport)
              puts "CN=#{cn}"

              cert = {
                :hostname => cn,
                :type => 'server',
                :user => 'watobo',
                :email => 'root@localhost',
              }
              cert_file, key_file = Watobo::CA.create_cert cert
              @fake_certs[dst] = {
                :cert => OpenSSL::X509::Certificate.new(File.read(cert_file)),
                :key => OpenSSL::PKey::RSA.new(File.read(key_file))
              }
            end
            ctx = OpenSSL::SSL::SSLContext.new()

            #ctx.cert = @cert
            ctx.cert = @fake_certs[dst][:cert]
            #  @ctx.key = OpenSSL::PKey::DSA.new(File.read(key_file))
            #ctx.key = @key
            ctx.key = @fake_certs[dst][:key]
            ctx.tmp_dh_callback = proc { |*args|
              @dh_key
            }

            ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
            ctx.timeout = 10

            ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
            ssl_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
            #  ssl_socket.sync_close = true
            ssl_socket.sync = true
            # puts ssl_socket.methods.sort

            ssl_session = ssl_socket.accept
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            #puts ssl_session
            #if not ssl_session then bscount += 1;end
            #if bscount > 10 then
            #  puts "!!! Error: SSL-Handshake with Client/Browser"
            #  puts bang
            return nil, socket
          #end
          #retry
          end
          session = ssl_session
          # puts "* ssl ok!"
          # now read ssl request header
          request = []
          Watobo::HTTPSocket.read_header(session) do |line|
            request.push line
          end

          return nil, session if not request.first

          request.first.gsub!(/(^[^[:space:]]{1,})( )(\/.*)/, "\\1 https://#{target}:#{tport}\\3")
        end
        #puts request
        # request.extend Watobo::Mixin::Parser::Url
        # request.extend Watobo::Mixin::Parser::Web10
        # request.extend Watobo::Mixin::Shaper::Web10
        #Watobo::Request.create request
        request = Watobo::Request.new(request)

        clen = request.content_length
        if  clen > 0 then
          body = ""
          Watobo::HTTPSocket.read_body(session) do |data|
            body += data
            break if body.length == clen
          end
        request.push body
        end

        return request, session
      end

      def isPassThrough?(request, response, s_sock, c_sock)
        begin
          reason = nil
          clen = response.content_length
          # no pass-through necessary if request method is HEAD
          return false if request.method =~ /^head/i

          if matchContentType?(response.content_type) then
            # first forward headers
            c_sock.write response.join
            reason = []
            reason.push "---> WATOBO: PASS_THROUGH <---"
            reason.push "Reason: Content-Type = #{response.content_type}"
          elsif clen > @contentLength
            # puts "PASS-THROUGH: #{response.content_length}"
            c_sock.write response.join
            reason = []
            reason.push "---> WATOBO: PASS_THROUGH <---"
            reason.push "Reason: Content-Length > #{@contentLength} (#{response.content_length})"
          end

          return false if reason.nil?
          reason.push "* DO MANUAL REQUEST TO GET FULL RESPONSE *"
          response.push reason.join("\n")
          chat = Watobo::Chat.new(request, response, :source => CHAT_SOURCE_INTERCEPT)
          #notify(:new_interception, chat)
          Watobo::Chats.add chat

          pass_through(s_sock, c_sock, clen)
          #  puts "* Close Server Socket..."
          closeSocket(c_sock)
          #  puts "* Close Client Socket..."
          closeSocket(s_sock)
          #  puts "... done."
          true
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        return false
        end
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def closeSocket(socket)
        #puts socket.class
        return false if socket.nil?
        begin
        #if socket.class.to_s =~ /SSLSocket/
          if socket.respond_to? :sysclose
          #socket.io.shutdown(2)
          socket.sysclose
          elsif socket.respond_to? :shutdown
          socket.shutdown(2)
          elsif socket.respond_to? :close
          socket.close
          end
          return true
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        false
      end

    end
  end
end
