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
          request.split(/\n/).each do |line|
            #puts line.unpack("H*")
            new_line = line
            parsed_line = ''
            pos = 0
            off = 0
            while pos >= 0 and pos < line.length
              /#{pattern}/.match(line[pos..-1])
              match = $1
              break if match.nil?
              #new_line = parsed_line
              expr = match.gsub(/%%/,"")
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
              start = line.index(match)

              parsed_line += line[off..start-1] if start > 0
              parsed_line += data
              pos = start + match.length
              off = pos
            end

            unless parsed_line.empty?
              parsed_line += line[off..-1]
              new_request += "#{parsed_line}\n"
            else
              new_request += "#{new_line}\n"
            end
            #puts new_request
          end

          return new_request

        rescue SyntaxError, LocalJumpError, NameError => e
          raise SyntaxError, "SyntaxError in '#{expr}'"
          #rescue LocalJumpError => e
          #  raise LocalJumpError, "(#{expr}) LocalJumpError!"
          #rescue NameError => e
          #  raise NameError, "(#{expr}) NameError!"
          #rescue => e
          #  puts e
          #  raise e, "(#{expr}) Not a valid expression!"
        end

        #   puts new_request
        return nil

      end

      def unchunked( opts = {} )
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

          result.extend Watobo::Mixin::Parser::Url
          result.extend Watobo::Mixin::Parser::Web10
          result.extend Watobo::Mixin::Shaper::Web10

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