# .
# scope.rb
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
  class Scope
    @scope = {}
    def self.to_s
      @scope.to_yaml
    end

    def self.to_yaml
      @scope.to_yaml
    end

    def self.set(scope)
      @scope = scope
    end

    def self.exist?
      return false if @scope.empty?
      @scope.each_value do |s|
        return true if s[:enabled] == true
      end
      return false
    end

    def self.reset
      @scope = {}
    end

    def self.each(&block)
      if block_given?
        @scope.each do |site, scope|
          yield [ site, scope]
        end
      end
    end

    def self.match_site?(site)
      return true if @scope.empty?
      @scope.has_key? site
    end

    def self.match_chat?(chat)
      #puts @scope.to_yaml
      return true if @scope.empty?

      site = chat.request.site

      if @scope.has_key? site

        path = chat.request.path
        url = chat.request.url.to_s
        scope = @scope[site]
       
        if scope.has_key? :root_path
          unless scope[:root_path].empty?
            return false unless path =~ /^(\/)?#{scope[:root_path]}/i
          end
        end
        return true unless scope.has_key? :excluded_paths
       

        scope[:excluded_paths].each do |p|
         # puts "#{url} - #{p}"
          return false if url =~ /#{p}/
        end
        
      return true
      end
      return false
    end

    def self.add(site)

      scope_details = {
        :site => site,
        :enabled => true,
        :root_path => '',
        :excluded_paths => [],
      }

      @scope[site] = scope_details
      return true
    end
  end
end