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
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))
  $: << inc_path
 
  require 'watobo'
  require 'fox16'
  
  include Fox

  module Watobo
    module Gui
    @application = FXApp.new('LayoutTester', 'FoxTest')  
 
  %w( load_icons gui_utils load_plugins session_history save_default_settings master_password session_history save_project_settings save_proxy_settings ).each do |l|
  f = File.join("watobo","gui","utils", l)
  require f
  #puts "Loading #{f}"
end

require 'watobo/gui/utils/init_icons'

gui_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib","watobo", "gui"))

Dir.glob("#{gui_path}/*.rb").each do |cf|
  next if File.basename(cf) == 'main_window.rb' # skip main_window here, because it must be loaded last
  require File.join("watobo","gui", File.basename(cf))
end

require 'watobo/gui/templates/plugin'
require 'watobo/gui/templates/plugin2'
require File.join(File.expand_path(File.dirname(__FILE__)), "crawler")

gui_path = File.join(File.expand_path(File.dirname(__FILE__)), "gui")

%w( crawler_gui settings_tabbook general_settings_frame status_frame hooks_frame auth_frame scope_frame ).each do |l|
  #puts "Loading >> #{l}"
  require File.join(gui_path, l + ".rb")
end
 
if ARGV.length > 0
    url = ARGV[0]
end
 
class TestGui < FXMainWindow
    
def initialize(app)
# Call base class initializer first
super(app, "Test Application", :width => 800, :height => 600)
frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
     
button = FXButton.new(frame, "Open Plugin",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,:padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
button.connect(SEL_COMMAND) {

  dlg = Watobo::Plugin::Crawler::Gui.new(self)
  
  if dlg.execute != 0
    puts dlg.details.to_yaml
  end  
}
end
    # Create and show the main window
def create
    super                  # Create the windows
    show(PLACEMENT_SCREEN) # Make the main window appear
    dlg = Watobo::Plugin::Crawler::Gui.new(self)
    dlg.set_tab_index 2
    prefs = { :form_auth_url => "http://www.google.com" }
    dlg.settings.auth.set prefs
      
    if dlg.execute != 0
        puts dlg.details.to_yaml
    end  
    end
  end
#  application = FXApp.new('LayoutTester', 'FoxTest')  
  TestGui.new(@application)
  @application.create
  @application.run
    end
end 


else

require File.join(File.expand_path(File.dirname(__FILE__)), "crawler")

gui_path = File.join(File.expand_path(File.dirname(__FILE__)), "gui")
%w( crawler_gui settings_tabbook general_settings_frame status_frame hooks_frame auth_frame scope_frame ).each do |l|
 #puts "Loading >> #{l}"
  require File.join(gui_path, l + ".rb")
end

end