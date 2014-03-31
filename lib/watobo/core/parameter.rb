# .
# parameter.rb
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
=begin 
  
 possible locations
 - url
 - header
 - cookie
 - data (body)

=end
  class Parameter
    attr :location
    attr :name
    attr_accessor :value
    
    def initialize(prefs)
      @location = nil
      @name = prefs[:name]
      @value = prefs[:value]
      @prefs = prefs      
    end
  end
  
  class WWWFormParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :data
    end
  end
  
  
  class UrlParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :url
    end
  end
  
  class CookieParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :cookie
    end
  end
  
  class XmlParameter < Parameter
    attr :parent
    attr :namespace
    def initialize(prefs)
      super prefs
      @location = :xml
      @parent = prefs.has_key?(:parent) ? prefs[:parent] : ""
      @namespace = prefs.has_key?(:namespace) ? prefs[:namespace] : nil
    end
  end
end