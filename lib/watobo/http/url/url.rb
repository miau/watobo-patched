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
  module HTTP
    class Url
      def to_s
        s = @root.url_string
      end
      
            
      def set(parm)
        if has_parm?(parm.name)
        @root.replace_get_parm(parm.name, parm.value)
        else
        @root.add_get_parm(parm.name, parm.value)
        end
      end

      def has_parm?(parm_name)
        @root.get_parm_names do |pn|
          return true if pn == parm_name
        end
        false
      end

      def parameters(&block)
        parms = []
        @root.get_parms.each do |p|
          name, val = p.split("=")
          parms << Watobo::UrlParameter.new( :name => name, :value => val )
        end
        parms
      end

      def initialize(root)
         @root = root

      end
    end
  end
end