# .
# goto_url_dialog.rb
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
  module Gui
    class GotoUrlDialog < FXDialogBox
      
      include Responder
      
      attr :url_pattern
      def initialize(owner, pattern=nil )
        #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        super(owner, "Enter URL filter (regex):", DECOR_ALL, :width => 300, :height => 150)
        
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @url_pattern = ""

      
       @pattern_field = FXTextField.new(base_frame, 40, :target => @pattern, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
        @pattern_field.setText(pattern) unless pattern.nil?
        @pattern_field.setFocus()
        @pattern_field.setDefault()

        @pattern_field.connect(SEL_KEYPRESS) { |sender, sel, event|
          if event.code == KEY_Tab
          @finishButton.setFocus()
          @finishButton.setDefault()
          true
          else
          false
          end

        }
        buttons_frame = FXHorizontalFrame.new(base_frame,
        :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
        
        
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
        #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
          true
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

      end
      
      private 
      
      def onAccept(sender, sel, event)
        begin
          @url_pattern = @pattern_field.text
          "regex_test".match(/#{@url_pattern}/)
        rescue
          @url_pattern = Regexp.quote @pattern_field.text
        end

       # Watobo::Scope.set @defineScopeFrame.getScope()

        getApp().stopModal(self, 1)
        self.hide()
        return 0
      end
    end
  end
end
