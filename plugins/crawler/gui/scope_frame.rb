# .
# scope_frame.rb
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
        

        class ScopeFrame < FXVerticalFrame
          def to_h
            {
              :allowed_hosts => @allowed_hosts_box.to_a,
              :allowed_urls => @allowed_urls_box.to_a,
              :excluded_urls => @exluded_urls_box.to_a
            }
          end
          
          def path_restricted?
            @restrict_path_cb.checked?
          end

          def set(s)
            @allowed_hosts_box.append s[:allowed_hosts] if s.has_key? :allowed_hosts
            @exluded_urls_box.append s[:allowed_urls] if s.has_key? :allowed_urls
            @exluded_urls_box.append s[:excluded_urls] if s.has_key? :excluded_urls

          end

          def update_form
            @widgets.each do |e|
              e.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
          end

          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            iframe = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|FRAME_THICK)
            #iframe = self
            @restrict_path_cb = FXCheckButton.new(iframe, "restrict to start path", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @restrict_path_cb.checkState = true

            outer_matrix = FXMatrix.new(iframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
            @allowed_hosts_box = Watobo::Gui::ListBox.new(outer_matrix, "Allowed Hosts")
            @exluded_urls_box = Watobo::Gui::ListBox.new(outer_matrix, "Excluded URLs")
            @allowed_urls_box = Watobo::Gui::ListBox.new(outer_matrix, "Allowed URLs")

          end

        end
      end
    end
  end
end