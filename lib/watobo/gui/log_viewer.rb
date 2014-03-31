# .
# log_viewer.rb
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
    class LogViewer < FXVerticalFrame
     
      include Watobo::Constants
      
      def purge
        @lock.synchronize do
           @log_viewer.text = ''
        end
      end

      def log(sender=nil, log_level, msg )
        puts "#{sender.class} => #{msg}" if $DEBUG
        begin
        t = Time.now
        now = t.strftime("%m/%d/%Y @ %H:%M:%S")

        begin
          log_text = case log_level
          when LOG_INFO
            "#{now}: #{msg}\n"
          else
            ""
          end
        rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        end
       @lock.synchronize do
         log_text << @log_message unless @log_message.nil?          
          @log_message = log_text
       end
         rescue => bang
           puts bang
           puts bang.backtrace
         end
        
      end

      def start_update_timer
         @timer = FXApp.instance.addTimeout( 50, :repeat => true) {
           @lock.synchronize do
             unless @log_message.nil?
             @log_viewer.insertText(0,@log_message) unless @log_message.empty? 
             @log_message = nil
             end
            end
          }
      end
      
      def destroy
        getApp().removeTimeout(@timer) unless @timer.nil?
        super
        1
      end
      
      def initialize(parent, opts)
        opts[:padding] = 0
        super(parent, opts)

        @log_message = nil
        @lock = Mutex.new
        @timer = nil
        
        #self.connect(SEL_CLOSE, method(:onClose))

        @log_viewer = FXText.new(self,  nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @log_viewer.editable = false
        start_update_timer
      end
      
    end

  end
end