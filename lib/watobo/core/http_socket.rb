# .
# http_socket.rb
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
    module HTTP
      def HTTP.read_body(socket, prefs=nil)
        buf = nil
        max_bytes = -1
        unless prefs.nil?
          max_bytes = prefs[:max_bytes] unless prefs[:max_bytes].nil?
        end
        bytes_to_read = max_bytes >= 0 ? max_bytes : 1024
        
        bytes_read = 0
        while max_bytes < 0 or bytes_to_read > 0 
          begin
            timeout(5) do
             # puts "<#{bytes_to_read} / #{bytes_read} / #{max_bytes}"
              buf = socket.readpartial(bytes_to_read)
              bytes_read += buf.length
            end
          rescue EOFError
            return
          rescue Timeout::Error
            puts "!!! Timeout: read_body (max_bytes=#{max_bytes})"
            #puts "* last data seen on socket:"
            # puts buf
            puts $!.backtrace if $DEBUG
            return
          rescue => bang
            print "E!"
            puts bang.backtrace if $DEBUG
            return
          end
          # puts bytes_read.to_s
          yield buf if block_given?
          return if max_bytes >= 0 and bytes_read >= max_bytes
          bytes_to_read -= bytes_read if max_bytes >= 0 && bytes_to_read >= bytes_read
        end
        #  end
      end

      def HTTP.readChunkedBody(socket)
        buf = nil
        while (chunk_size = socket.gets)
          next if chunk_size.strip.empty?
          yield "#{chunk_size}" if block_given?
          num_bytes = chunk_size.strip.hex
          # puts "> chunk-length: 0x#{chunk_size.strip}(#{num_bytes})"
          return if num_bytes == 0
          bytes_read = 0
          while bytes_read < num_bytes
            begin
              timeout(5) do
                bytes_to_read = num_bytes - bytes_read
                # puts bytes_to_read.to_s
                buf = socket.readpartial(bytes_to_read)
                bytes_read += buf.length
                # puts bytes_read.to_s
              end
            rescue EOFError
              # yield buf if buf
              return
            rescue Timeout::Error
              puts "!!! Timeout: readChunkedBody (bytes_to_read=#{bytes_to_read}"
              #puts "* last data seen on socket:"
              # puts buf
              return
            rescue => bang
              # puts "!!! Error (???) reading body:"
              # puts bang
              # puts bang.class
              # puts bang.backtrace.join("\n")
              # puts "* last data seen on socket:"
              # puts buf
              print "E!"
              return
            end
            # puts bytes_read.to_s
            yield buf if block_given?
            #return if max_bytes > 0 and bytes_read >= max_bytes
          end
          yield "\r\n" if block_given?
        end
        #  end
      end

      def HTTP.read_header(socket)
        buf = ''

        while true
          begin
            buf = socket.gets
          rescue EOFError
            puts "!!! EOF: reading header"
            # buf = nil
            return
          rescue Errno::ECONNRESET
            #puts "!!! CONNECTION RESET: reading header"
            #buf = nil
            #return
            raise
          rescue Errno::ECONNABORTED
            raise
          rescue Timeout::Error
            #puts "!!! TIMEOUT: reading header"
            #return
            raise
          rescue => bang
            puts "!!! READING HEADER:"
           # puts buf
            puts bang
            puts bang.backtrace if $DEBUG
          end

          return if buf.nil?

          yield buf if block_given?
          return if buf.strip.empty?
        end
      end

    end
end

