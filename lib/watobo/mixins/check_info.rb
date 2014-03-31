# .
# check_info.rb
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
  module CheckInfoMixin
    module InfoMethods
      def check_name
       
        #puts self.methods.sort
        info = instance_variable_get("@info")
        return nil if info.nil?
        return info[:check_name]
      end
      
      def check_group
        info = instance_variable_get("@info")
        return nil if info.nil?
        return info[:check_group]
      end

    end

    extend InfoMethods

    def self.included( other )
      other.extend InfoMethods
    end
  #:name => "#{check.info[:check_group]}|#{check.info[:check_name]}",

  end
end