# .
# active_checks.rb
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
  class ActiveModules
    @checks = []
    def self.each(&block)
      if block_given?
        @checks.map{|c| yield c }
      end

    end

    def self.to_a
      @checks
    end

    def self.length
      @checks.length
    end

    def self.init
      @checks = []
      active_path = Watobo.active_module_path
      Dir["#{active_path}/**"].each do |group|
        if File.ftype(group) == "directory"
          Dir["#{group}/*.rb"].each do |mod_file|
            begin
            #           module_file = File.join(active_path, group, modules)
              mod = File.basename(mod_file)
              group_name = File.basename(group)# notify(:logger, LOG_DEBUG, "loading module: #{module_file}")

              require mod_file

              group_class = group_name.slice(0..0).upcase + group_name.slice(1..-1).downcase
              #
              module_class = mod.slice(0..0).upcase + mod.slice(1..-1).downcase
              module_class.sub!(".rb","")

              ac = Watobo::Modules::Active.const_get(group_class).const_get(module_class)
              print "."
              
              @checks << ac
            rescue => bang
              puts bang
            end
          end
        end
      end
      @checks
    end
  end

end