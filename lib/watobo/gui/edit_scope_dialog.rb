# .
# edit_scope_dialog.rb
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
  module Gui
    class EditScopeDialog < FXDialogBox

      include Responder

      attr :scope
      def onAccept(sender, sel, event)

        @scope = @defineScopeFrame.getScope()

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

      def initialize(owner, project, prefs)
        #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        super(owner, "Edit Target Scope", DECOR_ALL, :width => 300, :height => 425)
        @project = project
        @scope = Hash.new

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        #  puts "create scopeframe with scope:"
        # @project.scope
        @defineScopeFrame = DefineScopeFrame.new(base_frame, @project.listSites(), YAML.load(YAML.dump(@project.scope)), prefs)

        buttons_frame = FXHorizontalFrame.new(base_frame,
        :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
        #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

      end
    end
  end
end
