# .
# plugin_base.rb
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
  class PluginBase
    def self.inherited(subclass)
      %w( plugin_name plugin_path description version author output_path config_path lib_path ).each do |cvar|
        define_method(cvar){ self.class.instance_variable_get("@#{cvar}")}
        define_singleton_method("get_#{cvar}"){ 
          return nil unless instance_variable_defined?("@#{cvar}")
          instance_variable_get("@#{cvar}")
          }
        define_singleton_method("#{cvar}"){ |val| instance_variable_set("@#{cvar}",val)}
      end
      path = File.join(File.dirname(caller[0]))      
      subclass.plugin_path path if File.exist?(path)
      lpath = File.join(path, "lib" )       
      subclass.lib_path lpath if File.exist?(lpath)
    end
    
    def self.load_libs(*order)
      lpath = get_lib_path
      if order.empty?
        libs = Dir.glob("#{lpath}/*")
      else
        libs = order
      end
      libs.each do |lib|
        puts "> #{lib.to_s}"
      require File.join(lib.to_s)
      end      
    end
    
    def self.gui
      @gui
    end

   
    def self.create_gui()
      if self.const_defined? :Gui
        gui = self.class_eval("Gui")
        @gui = gui.new()
        return @gui
      end
      puts "No GUI available for #{self}!"
      return nil

    end
    
    def self.load_gui(*order)
      # load if WATOBO is in GUI mode
      if Watobo.const_defined? :Gui
      # gui_path = File.join(File.dirname(caller[0]), "gui")
      gui_path = File.join(get_plugin_path, "gui")
      if order.empty?
        libs = Dir.glob("#{gui_path}/*")
      else
        libs = order
      end
      libs.each do |lib|
        puts "loading gui-lib #{lib} ..."
      require File.join(gui_path, lib.to_s)
      end
      else
        puts "WATOBO NOT IN GUI MODE!"
      end
    end

    def self.has_gui?
      puts self
      return true
    end
  end

  class PluginGui < FXDialogBox

    include Watobo::Gui
    include Watobo::Gui::Icons

    extend Watobo::Subscriber
    
    def self.inherited(subclass)
      %w( icon_file icons_path window_title width height config_path ).each do |cvar|
        define_method(cvar){ self.class.instance_variable_get("@#{cvar}")}
        define_singleton_method("get_#{cvar}"){ 
          return nil unless instance_variable_defined?("@#{cvar}")
          instance_variable_get("@#{cvar}")
          }
        define_singleton_method("#{cvar}"){ |val| instance_variable_set("@#{cvar}",val)}
      end
      
      base_class = class_eval( subclass.to_s.gsub(/::Gui/,''))
      plugin_path = base_class.get_plugin_path
      ipath = File.join(plugin_path, "icons")
      if File.exist?(ipath)
        # define_singleton_method("icons_path"){ "#{ipath}" }
        subclass.icons_path ipath
      end
      
    end
    
    
    def updateView()
      raise "!!! updateView not defined"
    end

    def initialize( opts = {} )
     # _width = instance_variable_get("@width")
     # puts _width
     # puts _width.class
     copts = { :opts => DECOR_ALL,:width=>800, :height=>600 }
     copts.update opts
      title = self.class.instance_variable_defined?("@window_title") ? window_title : "#{self}"
      super(Watobo::Gui.application, title, copts)

      @timer_lock = Mutex.new
      load_icon

    end

    private

    def load_icon
      ipath = icons_path
      ifile = icon_file
      return false if ipath.nil? or ifile.nil?
      
      myicon = File.join(ipath, ifile)
      if File.exist? myicon
      #puts "* loading icon > #{myicon}"
      self.icon = Watobo::Gui.load_icon(myicon) unless myicon.nil?
      else
        self.icon = nil
      end
    end

    def update_timer(ms=50, &block)
      update_timer = FXApp.instance.addTimeout( ms, :repeat => true) {
        @timer_lock.synchronize do
          if block_given?
            block.call if block.respond_to? :call
          end
        end
      }
    end

  end
end

