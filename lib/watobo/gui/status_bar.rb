# .
# status_bar.rb
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
      class StatusBar < FXHorizontalFrame

         def setStatusInfo( prefs={} )
            cprefs = {
               :color => self.parent.backColor,
               :text => ''
            }

            cprefs.update prefs unless prefs.nil?

            @statusInfo.text = cprefs[:text]
            unless cprefs[:color].nil?
               @statusInfo.backColor = cprefs[:color]
            end
         end

         def statusInfoText=( new_text )
            @statusInfo.text = new_text
            @statusInfo.backColor = self.parent.backColor
         end

         def projectName=(project_name)
            @projectName.text = project_name
         end

         def sessionName=(session_name)
            @sessionName.text = session_name
         end

         def portNumber=(port_number)
            @portNumber.text = port_number
         end

         def forwardingProxy=(forward_proxy)
            @forwardingProxy.text = forward_proxy
         end


         def initialize(owner, opts)
            super(owner, opts)

            frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
            FXLabel.new(frame, "Status: ")
            @statusInfo = FXLabel.new(frame, "- no project started -")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
            FXLabel.new(frame, "Project: ")
            @projectName = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
            FXLabel.new(frame, "Session: ")
            @sessionName = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
            FXLabel.new(frame, "Port: ")
            @portNumber = FXLabel.new(frame, " - ")

            frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
            FXLabel.new(frame, "Forwarding Proxy: ")
            @forwardingProxy = FXLabel.new(frame, " - ")
         end
      end
      # class end
   end
end
