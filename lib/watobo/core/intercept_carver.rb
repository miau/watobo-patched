# .
# intercept_carver.rb
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
  module Interceptor
    class CarverRule
      def action_name
        action.to_s
      end

      def location_name
        location.to_s
      end

      def pattern_name
        Regexp.quote pattern
      end

      def filter_name
        # return "NA" if filter.nil?
        return filter.class.to_s
      end
      
      def set_filter(filter_chain)
        puts "* set filter_chain"
        puts filter_chain.class
        @settings[:filter] = filter_chain
      end
      
      def filters
        return [] unless filter.respond_to? :list
        filter.list
      end

      def content_name
        content
      end

      def rewrite(item, l, p, c)
        res = false
        case l
        when :replace_all
          if File.exist? c
            begin
              puts "REPLACING RESPONSE"
              puts "OLD >>"
              puts item
              puts "NEW >>"
              item.replace Watobo::Utils.string2response(File.open(c,"rb").read)
              
              puts item 
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          else
            puts "Could not find file > #{c}"
          end
          
        when :body
          if item.respond_to? :body
            if p.upcase == :ALL
            res = item.replace_body(c)
            else
              puts "* rewrite body ..."
            res = item.rewrite_body(p,c)
            end
          end
        when :http_parm
          1
        when :cookie
          1
        when :url
          if item.respond_to? :url
            item.first.gsub!(/#{p}/, c)
          end
        when :http_header
          1
        end
        res
      end

      def apply(item, flags)
        begin
          unless filter.nil?
          return false unless filter.match?(item, flags)
          end
          res = case action
          when :flag
            puts "set flag >> #{content} (#{content.class})"
            flags << :request
            true
          when :inject
            inject_content(item, location, pattern, content)
          when :rewrite
            rewrite(item, location, pattern, content)
          else
            true
          end
          return res
        rescue => bang
          puts bang
          puts bang.backtrace
        end
      end

      def initialize(parms)
        @settings = Hash.new
        [:action, :location, :pattern, :content, :filter].each do |k|
          @settings[k] = parms[k]
        end

      end

      private

      def method_missing(name, *args, &block)
        # puts "* instance method missing (#{name})"
        @settings.has_key? name.to_sym || super
        @settings[name.to_sym]
      end
    end

    class Carver
      @rules = []
      
      def self.rules
        @rules
      end      
      
      def self.shape(response, flags)
        puts "Shape, Baby shape, ..."
      
       @rules.each do |r|
         res = r.apply( response, flags )
         puts "#{r.action_name} (#{r.action.class}) >> #{res.class}"
       end
      end
      
      def self.set_carving_rules(rules)
        @rules = rules
      end

      def self.add_rule(rule)
        @rules << rule if rule.respond_to? :apply
      end

      def self.clear_rules
        @rules.clear
      end      
    end
    
    class RequestCarver < Carver
       @rules = []      
    end
    
    class ResponseCarver < Carver
       @rules = []    
    end
  end
end