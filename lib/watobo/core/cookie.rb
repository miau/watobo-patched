# .
# cookie.rb
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

  #Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; path=/; secure
  class Cookie < Parameter

    attr :name
    attr :value
    attr :path
    attr :secure
    attr :http_only
    def name_value
      "#{@name}=#{@value}"
    end

    def initialize(cookie_prefs)
      @secure = false
      @http_only = false
      
      if cookie_prefs.respond_to? :has_key?
        @secure = prefs.has_key?(:secure) ? prefs[:secure] : false
        @http_only = prefs.has_key?(:http_only) ? prefs[:http_only] : false
        @location = :cookie
        @path = prefs[:path]
        @name = prefs[:name]
        @value = prefs[:value]
      else
        chunks = cookie_prefs.split(";")
        # first chunk
        @name, @value = chunks.first.split(":").last.split("=")
        
        m = cookie_prefs.match(/path=([^;]*)/)
        @path = m.nil? ? "" : m[1].strip
        @secure = true if chunks.select{|c| c =~ /Secure/i }
        @http_only = true if chunks.select{|c| c =~ /HttpOnly/i }
      end

      #if prefs.is_a? Hash
      #  #TODO: create cookie with hash-settings
      #  else
      #  raise ArgumentError, "Need hash (:name, :value, ...) or string (Set-Cookie:...)"
      #end
    end

  end
end