# .
# file_management.rb
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
  module Utils
    # e.g, save_settings("test-settings.test", 0, "@saved_settings", @saved_settings) 
    
    def Utils.save_settings(file, settings)
      begin
        if settings.is_a? Hash
          File.open(file, "w") { |fh|
            YAML.dump(settings, fh)
          }
          return true
        else
          return false
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return false
    end
    
    def Utils.loadSettings(file)
      
      if File.exists?(file) then
        # exp = File.open(file).read
        # settings = secure_eval(exp)
        settings = nil
        File.open(file,"r") { |fh|
          settings = YAML.load(fh)
        }
        return settings
      end
    end 
    
    def Utils.saveChat(chat, filename)
      chat_data = {
        :request => chat.request.map{|x| x.inspect},
        :response => chat.response.map{|x| x.inspect},
      }
      
      chat_data.update(chat.settings)                
      if File.exists?(filename) then
        puts "Updating #{filename}"
        File.open(filename, "w") { |fh| 
          YAML.dump(chat_data, fh)
        }
        chat.file = filename
      end
    end
    
  end
end
