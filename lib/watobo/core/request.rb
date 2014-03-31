# .
# request.rb
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
  def self.create_request(url, prefs={})
    unless url =~ /^https?:\/\//
      u = "http://#{url}"
    else
    u = url
    end

    uri = URI.parse u
    r = "GET #{uri.to_s} HTTP/1.0\r\n"
    r << "Host: #{uri.host}\r\n"
    r.extend Watobo::Mixins::RequestParser
    r.to_request
  end

  class Request < Array
    
    attr :data
    attr :url
    attr :header
   # attr :cookies
   
   include Watobo::HTTP::Cookies::Mixin
   include Watobo::HTTP::Xml::Mixin
    
    def self.create request
      request.extend Watobo::Mixin::Parser::Url
      request.extend Watobo::Mixin::Parser::Web10
      request.extend Watobo::Mixin::Shaper::Web10
     # request = Request.new(request)
      
    end
    
    def copy
      c = Watobo::Utils.copyObject self
      Watobo::Request.new c
    end
    
    def uniq_hash()
      begin
        settings = Watobo::Conf::Scanner.to_h
        hashbase = site + method + path
        
        get_parm_names.sort.each do |p|
          hashbase << p
          hashbase << get_parm_value(p) if settings[:non_unique_parms].include?(p)
        end

        post_parm_names.sort.each do |p|
        
          hashbase << p
          hashbase << post_parm_value(p) if settings[:non_unique_parms].include?(p)
        end
        # puts hashbase
        return Digest::MD5.hexdigest(hashbase)
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        return nil
      end
    end
    
    def parameters(*locations, &block)
      param_locations = [ :url, :data, :wwwform, :xml, :cookies ]
      unless locations.empty?
        param_locations.select!{ |loc| locations.include? loc }
      end
      
      parms = []
      parms.concat @url.parameters if param_locations.include?(:url)
      parms.concat cookies.parameters if param_locations.include?(:cookies)
      parms.concat @data.parameters if self.is_wwwform? and ( param_locations.include?(:data) or param_locations.include?(:wwwform) )
      
      parms.concat xml.parameters if self.is_xml? and param_locations.include?(:xml)
      if block_given?
        parms.each do |p|
          yield p
        end
      end
      parms
    end
    
    def set(parm)
      case parm.location
      when :data
        #
       # replace_post_parm(parm.name, parm.value)
       @data.set parm
      when :url
        @url.set parm
      when :xml
        xml.set parm
      when :cookie
        cookies.set parm
      end
      true
    end

    def initialize(r)
      if r.respond_to? :concat
        #puts "Create REQUEST from ARRAY"
       self.concat r
      elsif r.is_a? String
        if r =~ /^http/
          uri = URI.parse r
          self << "GET #{uri.to_s} HTTP/1.0\r\n"
          self << "Host: #{uri.host}\r\n"
        else
          r.extend Watobo::Mixins::RequestParser
        self.concat r.to_request
        end

      end
      self.extend Watobo::Mixin::Parser::Url
      self.extend Watobo::Mixin::Parser::Web10
      self.extend Watobo::Mixin::Shaper::Web10
      
      @url = Watobo::HTTP::Url.new(self)
      @data = Watobo::HTTPData::WWW_Form.new(self)
      @cookies = Watobo::HTTP::Cookies.new(self)
    end
  end
end