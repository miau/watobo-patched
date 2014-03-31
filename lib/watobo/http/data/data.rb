# .
# data.rb
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
  module HTTPData
    class Base
      def to_s
        s = @root.body.nil? ? "" : @root.body
      end

      def initialize(root)
        @root = root
      end
    end

    class WWW_Form < Base
      def set(parm)
        if has_parm?(parm.name)
        @root.replace_post_parm(parm.name, parm.value)
        else
        @root.add_post_parm(parm.name, parm.value)
        end
      end

      def has_parm?(parm_name)
        @root.post_parm_names do |pn|
          return true if pn == parm_name
        end
        false
      end

      def parameters(&block)
        parms = []
        @root.post_parms.each do |p|
          name, val = p.split("=")
          parms << Watobo::WWWFormParameter.new( :name => name, :value => val )
        end
        parms
      end

      def initialize(root)
        super root

      end
    end

  end

end