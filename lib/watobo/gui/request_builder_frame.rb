# .
# request_builder_frame.rb
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
    class RequestBuilder < FXVerticalFrame
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def setRequest(raw_request)
        begin
        # request
          if raw_request.is_a? String
            request = Watobo::Utils.text2request(raw_request)
          else
            request = Watobo::Request.new raw_request
          end
         

          @editors.each do |name, item|
            e = item[:editor]
            if e.setRequest(request)
              item[:tab_item].enable
            else
              item[:tab_item].disable
            end

          end

        rescue => bang
          puts bang
         puts bang.backtrace 
        # puts request
        # puts "== EOE =="
        end
      end

      def highlight(pattern)
       # @text_edit.highlight(pattern)
      end

      def rawRequest
       @current.rawRequest
      end

      def parseRequest

        @current.parseRequest
       
      end

      def initialize(owner, opts)
        super(owner,opts)

        @event_dispatcher_listeners = Hash.new
        @last_editor = nil

        @tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        @tab.connect(SEL_COMMAND){
          @current = @editors.to_a[@tab.current][1][:editor] 
          unless @last_editor.nil?
            last_request = @last_editor.rawRequest
            @current.setRequest(last_request)
          end
         @last_editor = @editors.to_a[@tab.current][1][:editor]
          #puts @current.class
          }
        @editors = {}
        @current = nil

        add_editor("Text") do |frame|
          Watobo::Gui::RequestEditor.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        end

        add_editor("Table") do |frame|
          Watobo::Gui::TableEditorFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        end
        
        @current = @editors.first[1][:editor]

      

      end

      private

      def add_editor(tab_name, &b)
        tab_item = FXTabItem.new(@tab, tab_name, nil)
        frame = FXVerticalFrame.new(@tab, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        editor = yield(frame) if block_given?

        @editors[tab_name.to_sym] = {
          :editor => editor,
          :tab_item => tab_item
        }
        editor.subscribe(:hotkey_ctrl_enter){ notify(:hotkey_ctrl_enter) }
        editor.subscribe(:error) { |msg| notify(:error, msg) }

      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end
    end
  end
end