# .
# password_policy_dialog.rb
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
    class PasswordPolicyDialog < FXDialogBox

      include Responder
      def passwordPolicy
        pp = {
          :save_passwords => @save_pws_cbt.checked?,
          :save_without_master => @save_without_cbt.checked?
        }
      end

      def initialize(owner, password_policy = {} )
        super(owner, "Password Policy", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 200, :height => 150)

        @password_policy = {
          :save_passwords => false,
          :save_without_master => false
        }
        @password_policy.update password_policy if password_policy.is_a? Hash

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @save_pws_cbt = FXCheckButton.new(frame, "save passwords")
        @save_pws_cbt.checkState = false
        @save_pws_cbt.checkState = true if @password_policy[:save_passwords] == true

        @save_pws_cbt.connect(SEL_COMMAND) {
          @save_without_cbt.enabled = @save_pws_cbt.checked?
        }

        @save_without_cbt = FXCheckButton.new(frame, "save without masterpassword")

        @save_without_cbt.enabled = @save_pws_cbt.checked?

        @save_without_cbt.checkState = false
        @save_without_cbt.checkState = true if @password_policy[:save_without_master] == true

        buttons = FXHorizontalFrame.new(frame, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        # Accept
        @acceptBtn = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        @acceptBtn.enable

        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        #  @hostname.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @domain.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @user.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @email.handle(self, FXSEL(SEL_UPDATE, 0), nil)

      end

      private

      def onAccept(sender, sel, event)

        if true then
          # puts "* new MasterPassword #{@master_password}"
          getApp().stopModal(self, 1)
          self.hide()
          return 1
        else
          FXMessageBox.information(self, MBOX_OK, "Wrong Passwords", "The passwords you've entered don't match!")
        end

      end
    end
  end
end

if __FILE__ == $0
  # TODO Generated stub
end