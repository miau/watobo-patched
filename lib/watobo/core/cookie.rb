# .
# cookie.rb
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
  
  
#Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; path=/; secure

  class Cookie
    
    attr :name
    attr :value
    attr :path
    attr :secure
    attr :http_only
    
    def name_value
    "#{@name}=#{@value}"  
    end
    
    def initialize(prefs)
      @value = nil
      @name = nil
      @secure = false
      @http_only = false
      @path = nil
      
      if prefs.is_a? String
        # remove Set-Cookie: from string
      #  puts "* create new Cookie"
      #  puts ">> #{prefs}"
        cs = prefs.gsub(/^Set-Cookie:/,'').strip.split(";").map{ |c| c.strip }
        @name, @value = cs.shift.split("=") 
        cs.each do |o|
          if o =~ /^path=(.*)/
            @path = $1
          end
          
          @secure = true if o =~ /secure/i
          @http_only = true if o =~ /httponly/i
        end
      elsif prefs.is_a? Hash
        #TODO: create cookie with hash-settings
      else
        raise ArgumentError, "Need hash (:name, :value, ...) or string (Set-Cookie:...)"
      end
    end
  end
  
  
end