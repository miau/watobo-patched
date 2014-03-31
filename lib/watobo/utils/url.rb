# .
# url.rb
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
  module Utils
    module URL
      def self.create_url(chat, path)
        url = path
        # only expand path if not url
        unless path =~ /^http/
          # check if path is absolute
          if path =~ /^\//
            url = File.join("#{chat.request.proto}://#{chat.request.host}", path)
          else
            # it's relative
            url = File.join(File.dirname(chat.request.url.to_s), path)
          end
        end
        # resolve path traversals
        while url =~ /(\/[^\.\/]*\/\.\.\/)/
          url.gsub!( $1,"/")
        end
        url
      end
    end
  end
end