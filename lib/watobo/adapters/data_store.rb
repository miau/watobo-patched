# .
# data_store.rb
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
  class DataStore
    
    @engine = nil
    
    def self.engine
      @engine
    end  
      
    def self.acquire(project_name, session_name)
      a = Watobo::Conf::Datastore.adapter
      store = case
      when 'file'
        FileSessionStore.new(project_name, session_name)
      else
        nil
      end
      @engine = store
      store
    end
    
        
  end
  
  def self.log(message, prefs={})
    if DataStore.engine.respond_to? :logger
      DataStore.engine.logger message, prefs
    end
  end
end