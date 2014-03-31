# .
# proxy.rb
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
  class Proxy
      include Watobo::Constants
      
      attr :login
      
      def method_missing(name, *args, &block)
          # puts "* instance method missing (#{name})"
          if @settings.has_key? name.to_sym
            return @settings[name.to_sym]
          else
            super
          end
        end
        
      def to_yaml
        @settings.to_yaml
      end


      def has_login?
       # puts @settings.to_yaml
        return false if @settings[:auth_type] == AUTH_TYPE_NONE
        return true
      end

      def initialize(prefs)
        @login = nil
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :host
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :port
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :name
        
        @settings = { 
          :auth_type => AUTH_TYPE_NONE, 
          :username => '', 
          :password => '',
          :domain => '',
          :workstation => ''}
        
        @settings.update prefs

      end
    end
end