# .
# gui.rb
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
begin
  print "\nLoading FXRuby ... this may take some time ... "
  require 'fox16'
  require 'fox16/colors'
  print "[OK]\n"
rescue LoadError
  print "[FAILED]\n"
  puts "!!! Seems like FXRuby is not installed !!!"
  puts "please check the installation tutorial at http://watobo.sourceforge.net"
  exit
end

  if RUBY_PLATFORM =~ /(linux|bsd|solaris|hpux|darwin)/i then
    begin
      require 'selenium-webdriver'
    rescue LoadError
      puts "To use the Preview-Featur of WATOBO on your platform (#{RUBY_PLATFORM}) you first must install the 'selenium-webdriver' gem."
      puts "Simply enter the command 'gem install selenium-webdriver'"
      puts "Press a key to continue or CTRL-C to abort."
      gets
    end
  end
      

include Fox

module Watobo
  module Gui
    @application = nil
    @icon_path = File.expand_path(File.join(File.dirname(__FILE__),"..","..","icons"))

    @project = nil
    def self.history
      unless defined? @history
        hf = Watobo::Conf::Gui.history_file
        wd = Watobo.working_directory
        
      history_file = File.join(wd , hf)
      @history = SessionHistory.new(history_file)
      end
      @history
    end

    def self.start
      #  create_application
      @main_window = Watobo::Gui::MainWindow.new(@application)
      FXToolTip.new(@application)
      
      @application.create
      @application.threadsEnabled = true
      
      Thread.abort_on_exception = true
      
      @history = Gui.history

      check_first_run()

      @application.run

    end

    def self.create_application
      @application = FXApp.new("Watobo", "The Webapplication Toolbox")
    end

    def self.application
      @application
    end

    def self.project
      @project
    end
    
    def self.project=(project)
      @project = project
    end
    
    def self.check_first_run
       # file = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "disclaimer.chk")
       file = File.join(Watobo.working_directory, "disclaimer.chk")
       unless File.exists?(file)
          first_start_info = Watobo::Gui::AboutWatobo.new(@main_window)
         if first_start_info.execute != 0 then
            File.new(file, "w")
         else
           exit
         end
       end
     end
  end
end

%w( load_icons gui_utils load_plugins session_history save_default_settings master_password session_history save_project_settings save_proxy_settings save_scanner_settings ).each do |l|
  require File.join("watobo","gui","utils", l)
end

Watobo::Gui.create_application

require 'watobo/gui/utils/init_icons'
require 'watobo/gui/mixins/subscriber'

gui_path = File.expand_path(File.join(File.dirname(__FILE__), "gui"))

Dir.glob("#{gui_path}/*.rb").each do |cf|
  next if File.basename(cf) == 'main_window.rb' # skip main_window here, because it must be loaded last
  require File.join("watobo","gui", File.basename(cf))
end

require 'watobo/gui/templates/plugin'
require 'watobo/gui/templates/plugin2'
require 'watobo/gui/main_window'