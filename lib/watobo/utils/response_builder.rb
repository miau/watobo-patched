# .
# response_builder.rb
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
  module Utils
      def self.string2response( text, opts = {} )
        options = { :update_content_length => false }
        options.update opts
        begin
          hb_sep = "\r\n\r\n"
          eoh = text.index(hb_sep)
          if eoh.nil?
            hb_sep = "\n\n"
            eoh = text.index(hb_sep)
          end
          unless eoh.nil?
          raw_header = text[0..eoh-1]
          raw_body = text[eoh+hb_sep.length..-1]
          puts ">> RawBody: #{raw_body}"
          else
            raw_header = text
            raw_body = nil
          end

          response = raw_header.split("\n")
          response.map!{|r| "#{r.strip}\r\n" }
          Watobo::Response.create response
          unless raw_body.nil?
          response << "\r\n"
          response << raw_body unless raw_body.strip.empty?
          end
          return response

        rescue => bang
          puts bang
          puts bang.backtrace
        end
        return nil
    end
  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  $: << inc_path

  require 'watobo'
  
text =<<'EOF'
HTTP/1.1 200 OK
Content-Type: text/html
Vary: Accept-Encoding
Expires: Thu, 19 Jul 2012 06:57:20 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache
Date: Thu, 19 Jul 2012 06:57:20 GMT
Content-Length: 203
Connection: close

<html></html>
EOF

text2 ="HTTP/1.1 200 OK\r\n" +
"Content-Type: text/html\r\n" +
"Vary: Accept-Encoding\r\n" +
"Expires: Thu, 19 Jul 2012 06:57:20 GMT\r\n" +
"Cache-Control: max-age=0, no-cache, no-store\r\n" +
"Pragma: no-cache\r\n" +
"Date: Thu, 19 Jul 2012 06:57:20 GMT\r\n" +
"Content-Length: 203\r\n" +
"Connection: close\r\n\r\n" +
"<html></html>\r\n"

unless ARGV[0].nil?
if File.exist? ARGV[0]
  text = File.open(ARGV[0],"rb").read
end
end
r = Watobo::Utils.string2response text
puts r.class
puts r.status
puts r.content_type
puts r
puts
puts "="
puts 
r = Watobo::Utils.string2response text2
puts r.class
puts r.status
puts r.content_type
puts r

end