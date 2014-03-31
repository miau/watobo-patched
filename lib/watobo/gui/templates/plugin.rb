# .
# plugin.rb
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
  module Template
    class Plugin < FXDialogBox
      attr :plugin_name
      attr :icon

include Watobo::Gui
      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def updateView()
        raise "!!! updateView not defined"
      end

      def load_icon(file=__FILE__)
        begin
          @icon = ICON_PLUGIN
          path = File.dirname(file)
        #  puts "... searching for icons in #{path}"
          file = Dir.glob("#{path}/*.ico").first

          #    puts "* load icon: #{file}"
          @icon = Watobo::Gui.load_icon(file) unless file.nil?

          self.icon = @icon
        rescue => bang
          puts "!!!Error: could not init icon"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def initialize(owner, title, project, opts)
        super(owner, title, :opts => DECOR_ALL,:width=>800, :height=>600)
        # Implement Sender
        # Implement Scanner
        @icon = nil
        #        load_icon()
        @plugin_name = "undefined"
        @event_dispatcher_listeners = Hash.new

      end
    end
  end
end
