# .
# passive_checks.rb
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
  class PassiveModules
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
      passive_modules = []

      Dir["#{Watobo.passive_module_path}/*.rb"].each do |mod_file|
        begin
          mod = File.basename(mod_file)

          load mod_file
        rescue => bang
          puts "!!!"
          puts bang
        end
      end

      Watobo::Modules::Passive.constants.each do |m|
        begin
          class_constant = Watobo::Modules::Passive.const_get(m)
          pc = class_constant.new(self)
          print "."
          @checks << pc

        rescue => bang
          puts "!!!"
          puts bang
        end
      end
      
      passive_modules
    end
  end
end