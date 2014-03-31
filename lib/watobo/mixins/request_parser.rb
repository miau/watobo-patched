# .
# request_parser.rb
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
  module Mixins
    # This mixin can be used to parse a String or any object which supports method.to_s into a valid http request string
    module RequestParser
      # This method parses (eval) ruby code which is included in the string.
      # Ruby code is identified by its surrounding delimiters - default: '%%'.
      # For examples the string 'ABC%%"_"*10%%DEFG' will result to 'ABC__________DEFG'
      #
      # Possible prefs:
      #
      # :code_dlmtr [String] - set ruby code delimiter
      
      def parse_code(prefs={})
        cprefs = { :code_dlmtr => '%%' } # default delimiter for ruby code
        cprefs.update(prefs)

        pattern="(#{cprefs[:code_dlmtr]}.*?#{cprefs[:code_dlmtr]})"
        request = self.to_s

        begin
          # puts new_request
          expr = ''
          new_request = ''
          pos = 0
          off = 0
          while pos >= 0 and pos < request.length
             code_offset = request.index(/#{pattern}/, pos)
          unless code_offset.nil?
            expression = request.match(/#{pattern}/, code_offset)[0]
              new_request << request[pos..code_offset-1]
              expr = expression.gsub(/%%/,"")
              puts "DEBUG: executing: #{expr}" if $DEBUG
              result = eval(expr)
              puts "DEBUG: got #{result.class}" if $DEBUG
              if result.is_a? File
                data = result.read
                result.close
              elsif result.is_a? String
                data = result
              elsif result.is_a? Array
                data = result.join
              else
                log("!!!WATOBO - expression must return String or File !!!",'')
              end
              new_request << data
              pos = code_offset + expression.length
            else
              new_request << request[pos..-1]
              pos = request.length
            end
          end
          return new_request

        rescue SyntaxError, LocalJumpError, NameError => e
          raise SyntaxError, "SyntaxError in '#{expr}'"
        end
        return nil
      end

      def unchunked_UNUSED( opts = {} )
        options = { :update_content_length => false }
        options.update opts
        begin
          text = parse_code
          eoh = self.index("\n\n")
          unless eoh.nil?
            raw_header = text[0..eoh-1]
            raw_body = text[eoh+1..-1]
          else
            raw_header = text
            raw_body = nil
          end

          unchunked = raw_header.split("\n")
          unchunked.extend Watobo::Mixin::Parser::Url
          unchunked.extend Watobo::Mixin::Parser::Web10
          unchunked.extend Watobo::Mixin::Shaper::Web10

          unless raw_body.nil?
            unchunked
          end

        rescue => bang
        end
      end

      def to_request(opts={})
        options = { :update_content_length => false }
        options.update opts
        begin
          text = parse_code
          result = []

          if text =~ /\n\n/
            dummy = text.split(/\n\n/)
            header = dummy.shift.split(/\n/)
            body = dummy.join("\n\n")
          else
            header = text.split(/\n/)
            body = nil
          end

          header.each do |h|
            result.push "#{h}\r\n"
          end

         # result.extend Watobo::Mixin::Parser::Url
         # result.extend Watobo::Mixin::Parser::Web10
         # result.extend Watobo::Mixin::Shaper::Web10
         Watobo::Request.create result

          ct = result.content_type
          # last line is without "\r\n" if text has a body
          if ct =~ /multipart\/form/ and body then
            #Content-Type: multipart/form-data; boundary=---------------------------3035221901842
            if ct =~ /boundary=([\-\w]+)/
              boundary = $1.strip
              chunks = body.split(boundary)
              e = chunks.pop # remove "--"
              new_body = []
              chunks.each do |c|
                new_chunk = ''
                c.gsub!(/[\-]+$/,'')
                next if c.nil?
                next if c.strip.empty?
                c.strip!
                if c =~ /\n\n/
                  ctmp = c.split(/\n\n/)
                  cheader = ctmp.shift.split(/\n/)
                  cbody = ctmp.join("\n\n")
                else
                  cheader = c.split(/\n/)
                  cbody = nil
                end
                new_chunk = cheader.join("\r\n")
                new_chunk +=  "\r\n\r\n"
                new_chunk += cbody.strip + "\r\n" if cbody

                # puts cbody
                new_body.push new_chunk

              end
              body = "--#{boundary}\r\n"
              body += new_body.join("--#{boundary}\r\n")
              body += "--#{boundary}--"
            end
            #  body.gsub!(/\n/, "\r\n") if body

          end

          if body then
            result.push "\r\n"
            result.push body.strip
          end

          result.fixupContentLength() if options[:update_content_length] == true
          return result
        rescue
          raise
        end
        #return nil
      end


      def to_request_UNUSED(opts={})
        options = { :update_content_length => false }
        options.update opts
        begin
          text = parse_code
          result = []

          if text =~ /\n\n/
            dummy = text.split(/\n\n/)
            header = dummy.shift.split(/\n/)
            body = dummy.join("\n\n")
          else
            header = text.split(/\n/)
            body = nil
          end

          header.each do |h|
            result.push "#{h}\r\n"
          end

         # result.extend Watobo::Mixin::Parser::Url
         # result.extend Watobo::Mixin::Parser::Web10
         # result.extend Watobo::Mixin::Shaper::Web10
         Watobo::Request.create result

          ct = result.content_type
          # last line is without "\r\n" if text has a body
          if ct =~ /multipart\/form/ and body then
            #Content-Type: multipart/form-data; boundary=---------------------------3035221901842
            if ct =~ /boundary=([\-\w]+)/
              boundary = $1.strip
              chunks = body.split(boundary)
              e = chunks.pop # remove "--"
              new_body = []
              chunks.each do |c|
                new_chunk = ''
                c.gsub!(/[\-]+$/,'')
                next if c.nil?
                next if c.strip.empty?
                c.strip!
                if c =~ /\n\n/
                  ctmp = c.split(/\n\n/)
                  cheader = ctmp.shift.split(/\n/)
                  cbody = ctmp.join("\n\n")
                else
                  cheader = c.split(/\n/)
                  cbody = nil
                end
                new_chunk = cheader.join("\r\n")
                new_chunk +=  "\r\n\r\n"
                new_chunk += cbody.strip + "\r\n" if cbody

                # puts cbody
                new_body.push new_chunk

              end
              body = "--#{boundary}\r\n"
              body += new_body.join("--#{boundary}\r\n")
              body += "--#{boundary}--"
            end
            #  body.gsub!(/\n/, "\r\n") if body

          end

          if body then
            result.push "\r\n"
            result.push body.strip
          end

          result.fixupContentLength() if options[:update_content_length] == true
          return result
        rescue
          raise
        end
        #return nil
      end

    end
  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..","lib"))
  $: << inc_path

  require 'watobo'
  
text =<<'EOF'
%%"GET"%% http://www.siberas.de/ HTTP/1.1
Content-Type: text/html
%%"x"*10%%Vary: Accept-Encoding
Expires: Thu, 19 Jul 2012 06:57:20 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache
Date: Thu, 19 Jul 2012 06:57:20 GMT
Content-Length: 203
Connection: close%%"XXXX"%%

<html></html>
EOF

text.strip!
puts text
puts 
puts "==="
puts 
text.extend Watobo::Mixins::RequestParser
puts text.to_request
Watobo::Utils.hexprint text
end