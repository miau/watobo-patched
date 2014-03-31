# .
# cookies.rb
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
  module HTTP
    class Cookies
      def to_s
        s = @root.url_string
      end
      
            
      def set(parm)
       
      end

      def has_parm?(parm_name)
        false
      end

      def parameters(&block)
        parms = []
        cookie_list=[]
        cookie_prefs={ :secure => false, :http_only => false }
        @root.headers.each do |line|
          if line =~ /^(Set\-)?Cookie2?: (.*)/i then
            cookie_prefs[:secure] = true if line =~ /secure/i
          cookie_prefs[:http_only] = true if line =~ /httponly/i
            clist = $2.split(";")
            clist.each do |c|
             name, value = c.strip.split("=").map{|v| v.strip}
             puts "NEW COOKIE: #{name} - #{value}"
             cookie_prefs[:name] = name
             cookie_prefs[:value] = value
             cookie = Watobo::CookieParameter.new(cookie_prefs)
             yield cookie if block_given?
             cookie_list << cookie
            end
          end
        end
        return cookie_list
      end

      def initialize(root)
         @root = root

      end
    end
  end
end