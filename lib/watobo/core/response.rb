# .
# response.rb
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
  class Response < Array
    def self.is_html?
      
    end
    
    def self.is_json?
      
    end
    
    
    
    
    def self.create( response )
      raise ArgumentError, "Array Expected." unless response.is_a? Array
      response.extend Watobo::Mixin::Parser::Url
      response.extend Watobo::Mixin::Parser::Web10
      response.extend Watobo::Mixin::Shaper::Web10
      response.extend Watobo::Mixin::Shaper::HttpResponse
    end
    
    def data
      @data
    end

    def copy
      c = YAML.load(YAML.dump(self))
      Watobo::Request.new c
    end
    
    def initialize(r)
      if r.respond_to? :concat
        #puts "Create REQUEST from ARRAY"
       self.concat r
      elsif r.is_a? String
       raise ArgumentError, "Need Array"
      end
      self.extend Watobo::Mixin::Parser::Url
      self.extend Watobo::Mixin::Parser::Web10
      self.extend Watobo::Mixin::Shaper::Web10
      self.extend Watobo::Mixin::Shaper::HttpResponse
      
      if content_type =~ /(html|text)/
        self.extend Watobo::Parser::HTML
      end
      
    end
  end
end