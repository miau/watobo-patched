# .
# settings_tabbook.rb
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
  module Plugin
    module Crawler
      class Gui
        class SettingsTabBook < FXTabBook
          attr :hooks, :general, :log_viewer, :auth, :scope
          
          
          
          def initialize(owner)
            #@tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            super(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            FXTabItem.new(self, "General", nil)
            # frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            @general = GeneralSettingsFrame.new(self)
            
            FXTabItem.new(self, "Scope", nil)
            @scope = ScopeFrame.new(self)
            
            FXTabItem.new(self, "Auth", nil)
            @auth = AuthFrame.new(self)

            
            FXTabItem.new(self, "Hooks", nil)
            @hooks = HooksFrame.new(self)
            
            FXTabItem.new(self, "Log", nil)
            frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_RAISED)
            @log_viewer = Watobo::Gui::LogViewer.new(frame, :append, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
            
            self.connect(SEL_COMMAND){
              @hooks.selected if self.current == 3
            }
          end
        end
      end
    end
  end
end