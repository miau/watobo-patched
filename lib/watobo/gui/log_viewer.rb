# .
# log_viewer.rb
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
    class LogViewer < FXVerticalFrame

      include Watobo::Constants
      def purge_logs
        begin
          @log_text_lock.synchronize do
            @textbox.setText('')
          # @textbox.makePositionVisible 0
          end
        rescue => bang
          puts "! Could not purge logs"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      # LOG_INFO
      def log(log_level, msg )

        t = Time.now
        now = t.strftime("%m/%d/%Y @ %H:%M:%S")

        begin
          log_text = case log_level
          when LOG_INFO
            "#{now}: #{msg}\n"
          else
          ""
          end
          @log_queue << log_text
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def initialize(parent, mode = nil, opts)
        opts[:padding]=0
        
        @mode = mode.nil? ? :inster : mode

        super(parent, opts)

        @log_queue = Queue.new

        @log_text_lock = Mutex.new

        @textbox = FXText.new(self,  nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @textbox.editable = false
        start_update_timer
      end

      private

      def start_update_timer
        @timer = FXApp.instance.addTimeout( 150, :repeat => true) {
          #print @log_queue.length
          if @log_queue.length > 0
            msg = @log_queue.deq
            if @mode == :insert
              @log_text_lock.synchronize do
                 @textbox.insertText(0,msg)
               end
            else
              @log_text_lock.synchronize do
                 @textbox.appendText(msg)
               end
            end
             @textbox.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end
          }

      end
     
    end

  end
end