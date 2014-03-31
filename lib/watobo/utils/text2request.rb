# .
# text2request.rb
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
    def Utils.text2request(text)
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
        
        
        return result
      
    end
  end
end

if __FILE__ == $0
  # TODO Generated stub
end
