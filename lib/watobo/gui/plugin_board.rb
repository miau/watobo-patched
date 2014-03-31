# .
# plugin_board.rb
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

      class PluginBoard < FXVerticalFrame
         include Watobo::Gui::Icons

         def updateBoard()

            return false unless Watobo::Gui.plugins.first.respond_to? :plugin_name
            begin
               @matrix.each_child do |child|
                  @matrix.removeChild(child)
               end

               Watobo::Gui.plugins.each do |p|
                  pbtn = FXButton.new( @matrix, "\n"+p.plugin_name, p.icon, nil, 0,
                  :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT|LAYOUT_RIGHT,
                  :width => 80, :height => 80)
                  pbtn.create

                  pbtn.connect(SEL_COMMAND) {
                     p.create
                     p.show(Fox::PLACEMENT_SCREEN)
                     p.updateView()
                  }

                  frame = FXFrame.new(@matrix, :opts => FRAME_NONE|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 80, :height => 80)
                  frame.backColor = FXColor::White
               end

               @plugin_frame.recalc
               @plugin_frame.update

            rescue => bang
               puts bang
               puts bang.backtrace if $DEBUG
            end
         end

         def initialize(parent)
            begin

               super(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
               # db_title = FXLabel.new(self, "PLUGIN-BOARD", :opts => LAYOUT_LEFT)
               main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
               main.backColor = FXColor::White

               frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
               frame.backColor = FXColor::White
               title_icon = FXButton.new(frame, '', ICON_PLUGIN, :opts => FRAME_NONE)
               title_icon.backColor = FXColor::White


               @font_title = FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT)
               title  = FXLabel.new(frame, "Plugin-Board", nil, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
               title.backColor = FXColor::White
               title.setFont(@font_title)
               title.justify = JUSTIFY_LEFT|JUSTIFY_CENTER_Y

               @plugin_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

               @plugin_frame.backColor = FXColor::White

               @matrix = FXMatrix.new(@plugin_frame, 7, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
               @matrix.backColor = FXColor::White
            rescue => bang
               puts bang
               puts bang.backtrace if $DEBUG
            end
            # update(nil)
         end
      end
   end
end
