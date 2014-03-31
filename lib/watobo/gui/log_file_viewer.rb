# .
# log_file_viewer.rb
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
    class LogFileViewer < FXVerticalFrame

      include Watobo::Constants
      def show_logs
        begin
           @textbox.setText(Watobo.logs)
        rescue => bang
          puts "! Could not show logs"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

   
      def initialize(parent, mode = nil, opts)
        opts[:padding]=0
        
        super(parent, opts)

        update_btn = FXButton.new(self, "Update",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){ show_logs }
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
        @textbox = FXText.new(frame,  nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_AUTOSCROLL|TEXT_READONLY)
        @textbox.editable = false
      show_logs  
   
      end
      
          end

  end
end