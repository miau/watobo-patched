# .
# status_frame.rb
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
  module Plugin
    module Crawler
      class Gui
        class StatusFrame < FXHorizontalFrame

          include Watobo::Plugin::Crawler::Constants
          # :engine_status => CRAWL_NONE,
          # :page_size => 0,
          # :link_size => 0,
          # :skipped_domains => 0
          def update_status(status)
            if status.has_key? :engine_status
              case status[:engine_status]
              when CRAWL_NONE
                self.backColor = self.parent.backColor
                @status_txt.text = "Status: Idle"
              when CRAWL_RUNNING
                self.backColor = FXColor::Red
                @status_txt.text = "Status: Running"

              when CRAWL_PAUSED
                self.backColor = FXColor::Yellow
                @status_txt.text = "Status: Paused"
              end
            end

            if status.has_key? :link_size
              @link_size_txt.text = "Links: #{status[:link_size]}"
            end

            if status.has_key? :page_size
              @page_size_txt.text = "Pages: #{status[:page_size]}"
            end
            
            if status.has_key? :total_requests
              @requests_txt.text = "Requests: #{status[:total_requests]}"
            end
          end

          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X|FRAME_RAISED)
            @info_fields = []
            #frame = FXHorizontalFrame.new(, :opts => LAYOUT_FILL_Y, :padding => 0)
            frame = self
            @info_fields << ( @status_txt = FXLabel.new(frame, "Status: Stopped", :opts => FRAME_SUNKEN|LAYOUT_FIX_WIDTH, :width => 100) )
            @info_fields << (@link_size_txt = FXLabel.new(frame, "Links: 0", :opts => FRAME_SUNKEN|LAYOUT_FIX_WIDTH, :width => 70) )
            @info_fields << (@page_size_txt = FXLabel.new(frame, "Pages: 0", :opts => FRAME_SUNKEN|LAYOUT_FIX_WIDTH, :width => 70) )
            @info_fields << (@requests_txt = FXLabel.new(frame, "Requests: 0", :opts => FRAME_SUNKEN|LAYOUT_FIX_WIDTH, :width => 100) )

            @info_fields.each do |i|
              i.justify = JUSTIFY_LEFT
            end
          end

        end
      end
    end
  end
end