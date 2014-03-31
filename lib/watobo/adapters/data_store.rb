# .
# data_store.rb
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
  class DataStore
    
    @engine = nil
    
    def self.engine
      @engine
    end  
      
    def self.connect(project_name, session_name)
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
    
    def self.method_missing(name, *args, &block)
      super unless @engine.respond_to? name
      @engine.send name, *args, &block
    end
    
        
  end
  
  def self.logs
    return "" if DataStore.engine.nil?
    DataStore.engine.logs
  end
  
  def self.log(message, prefs={})
    
    text = message
    if message.is_a? Array
      text = message.join("\n| ")
    end
    
    #clean up sender's name
    if prefs.has_key? :sender
      prefs[:sender].gsub!(/.*::/,'')
    end
    
    if DataStore.engine.respond_to? :logger
      DataStore.engine.logger message, prefs
    end
  end
end