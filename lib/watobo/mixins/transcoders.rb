# .
# transcoders.rb
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
  module Mixin
    module Transcoders
      def url_encode
        CGI::escape(self)
      end

      def url_decode
        CGI::unescape(self)
      end

      def b64decode
        err_count = 0
          b64string = self
        begin
          rs = Base64.strict_decode64(b64string)
          #rs = Base64.decode64(b64string)
          return rs
        rescue
          b64string.gsub!(/.$/,'')
          err_count += 1
          retry if err_count < 4
          return ""
        end
      end

      def b64encode
        begin
          plain = self
          #rs = Base64.strict_encode64(plain)
          rs = Base64.strict_encode64(plain)
          # we only need a simple string without linebreaks
          #rs.gsub!(/\n/,'')
          #rs.strip!
          return rs
        rescue
          return ""
        end
      end

      def hex2int
        begin
          plain = self.strip
          if plain =~ /^[0-9a-fA-F]{1,8}$/ then
          return plain.hex
          else
            return ""
          end
        rescue
          return ""
        end
      end

      def hexencode
        begin

          self.unpack("H*")[0]
        rescue
          return ""
        end

      end

      def hexdecode

        [ self ].pack("H*")
      end
    end
  end
end
