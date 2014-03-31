# .
# sites_tree.rb
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
#require 'qcustomize.rb'

module Watobo
  module Gui
    class SitesTree < FXTreeList
      attr_accessor :project

      include Watobo::Constants
      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def reload()
        self.clearItems

        @project.chats.each do |chat|
          addChat(chat)
        end

      # @interface.updateRequestTable(@project)
      end

def refresh_tree()
        self.clearItems

        @project.chats.each do |chat|
          addChat(chat)
        end

      # @interface.updateRequestTable(@project)
      end
      def expandFullTree(item)
        self.expandTree(item)
        item.each do |c|
          expandFullTree(c) if !self.itemLeaf?(c)
        end
      end

      def useSmallIcons()
        small_font = FXFont.new(getApp(), "helvetica", GUI_SMALL_FONT_SIZE)
        small_font.create
        @folderIcon = ICON_FOLDER_SMALL
        @reqIcon = ICON_REQUEST_SMALL
        @siteIcon= ICON_SITE_SMALL
        self.font = small_font
        reload()
      end

      def useRegularIcons()
        regular_font = FXFont.new(getApp(), "helvetica", GUI_REGULAR_FONT_SIZE)
        regular_font.create
        # Findings Tree Icons
        @folderIcon = ICON_FOLDER
        @reqIcon = ICON_REQUEST
        @siteIcon= ICON_SITE
        self.font = regular_font
        reload()
      end

      def collapseFullTree(item)
        self.collapseTree(item)
        item.each do |c|
          collapseFullTree(c) if !self.itemLeaf?(c)
        end
      end

      def hidden?(chat)

        #TODO: Filter
        false
      end

      def hideDomain(domain_filter)
        # @interface.default_settings[:domain_filters].push domain_filter
        # @interface.updateTreeLists()
      end

      def addChat(chat)
        add_chat = true

        add_chat = @project.siteInScope?(chat.request.site) if @show_scope_only == true
        @tree_filters[:response_status].each do |rf|
        #puts "#{chat.response.status} / #{rf}"
          add_chat = false if chat.response.status =~ /#{rf}/
        end

        addChatItem(chat) if add_chat
      end

      # end
      def addChatItem(chat)

        site = self.findItem(chat.request.site, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

        if not site then
        # found new site
        site = self.appendItem(nil, chat.request.site, @siteIcon, @siteIcon)
        #site = @findings_tree.moveItem(project.first,project,site)
        self.setItemData(site, :item_type_site)

        end

        @quick_filter[site.object_id] ||= []
        @quick_filter[site.object_id].push chat

        folder_parent = site
        #puts "ADD_REQUEST: #{chat.request.first}"
        dir = chat.request.dir

        if dir != "" then
          #puts "Check Folder: #{chat.request.path} - #{chat.request.site}" if path =~ /jump/
          folders = dir.split('/')
          folders.each do |folder_name|
          #   puts "search for folder #{folder_name}"
            folder_item = nil
            folder_parent.each do |c|
              folder_item = c if c.to_s == folder_name
            end
            #folder_item = self.findItem(folder_name, folder_parent, SEARCH_FORWARD|SEARCH_WRAP)
            if folder_item.nil? then
            #folder_item = self.appendItem(folder_parent, folder_name, @folderIcon, @folderIcon)
            folder_item = self.insertItem(folder_parent.first, folder_parent, folder_name, @folderIcon, @folderIcon)
            self.setItemData(folder_item, :item_type_folder)

            #     puts "added folder #{folder_name} to #{folder_parent} for site #{chat.request.site}"
            end
            @quick_filter[folder_item.object_id] ||= []
            @quick_filter[folder_item.object_id].push chat
            folder_parent = folder_item
          end
        end
        ml = 25
        fext = chat.request.file_ext
        element = "/" + fext.slice(0, ml)
        element += "..." if fext.length > ml

        item = nil
        folder_parent.each do |c|
          item = c if c.to_s == element
        end

        if item.nil?
        # puts item.text.methods.sort

        # puts "added file #{element} to #{folder_parent} for site #{chat.request.site}" if chat.request.url =~ /series60/i
        new_item = self.appendItem(folder_parent, element, @reqIcon, @reqIcon)
        #   self.textColor = FXColor::Red
        self.setItemData(new_item, chat)
        @quick_filter[new_item.object_id] ||= []
        #puts new_item.class
        @quick_filter[new_item.object_id].push chat
        end

      end

      def initialize(parent, interface, project)
        @project = project
        @interface = interface
        @parent = parent
        @quick_filter = Hash.new
        @show_scope_only = false

        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT)

        @event_dispatcher_listeners = Hash.new

        @projectIcon = ICON_PROJECT

        @folderIcon = ICON_FOLDER
        @reqIcon = ICON_REQUEST
        @siteIcon= ICON_SITE

        @filtered_domains = Hash.new # domains which already have been filtered

        @tree_filters = {
          :response_status => []
        }
        #    session_leaf = self.appendItem(nil, @session_name, @projectIcon, @projectIcon)

        self.connect(SEL_COMMAND) do |sender, sel, item|
          url_parts = []
          #  p = item
          if self.itemLeaf?(item)
            getApp().beginWaitCursor do
              begin
                if item.data
                #if item.data.class.to_s =~ /Qchat/
                #@interface.show_chat(item.data)
                notify(:show_chat, item.data)
                #end
                chat = item.data
                #         url_parts.unshift chat.request.file_ext
                #         p = item.parent
                end
              rescue => bang
              #  puts bang
              #  puts bang.backtrace if $DEBUG
              #puts "!!! Error: could not show selected tree item"
              end
            end
          #elsif item.data == :item_type_folder||:item_type_site then
          end
          # if !p.nil?
          #   while p.parent
          #    url_parts.unshift p.text.sub(/^\//,'')
          #    p = p.parent
          #  end
          #end
          #   url_parts.unshift p
          #   filter = url_parts.join("/")
          #   puts @quick_filter.keys.join("\n")
          #   puts "===="
          #   puts item
          #   puts "===="
          notify(:show_conversation, @quick_filter[item.object_id]) if @quick_filter[item.object_id]
        #  notify(:apply_site_filter, filter)

        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          exclude_site = nil
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|

              target = FXMenuCheck.new(menu_pane, "show scope only" )
              target.check = @show_scope_only

              target.connect(SEL_COMMAND) { |tsender, tsel, titem|
                @show_scope_only = tsender.checked?
                reload() if @project
              }

              exclude_submenu = FXMenuPane.new(self) do |sub|
                ["404", "302"].each do |rc|
                  target = FXMenuCheck.new(sub, "#{rc} Status" )

                  target.check = @tree_filters[:response_status].include?(rc)

                  target.connect(SEL_COMMAND) {
                    status = target.to_s.slice(/\d+/)
                    if sender.checked?()
                    @tree_filters[:response_status].push status
                    else
                    @tree_filters[:response_status].delete(status)
                    end
                    reload() if @project
                  }
                end
              end
              FXMenuCascade.new(menu_pane, "Hide", nil, exclude_submenu)

              item = sender.getItemAt(event.win_x, event.win_y)

              unless item.nil?

                unless self.itemLeaf?(item)
                  FXMenuSeparator.new(menu_pane)
                  FXMenuCommand.new(menu_pane, "expand tree" ).connect(SEL_COMMAND) {
                    expandFullTree(item)
                  }

                  FXMenuCommand.new(menu_pane, "collapse tree" ).connect(SEL_COMMAND) {
                    self.collapseFullTree(item)
                  }

                end

                data = self.getItemData(item)

                if data == :item_type_site then
                  FXMenuSeparator.new(menu_pane)

                  FXMenuCommand.new(menu_pane, "add site to scope" ).connect(SEL_COMMAND) {

                    notify(:add_site_to_scope, item.to_s)
                  }

                elsif data.is_a? Watobo::Chat

                  FXMenuSeparator.new(menu_pane)
                  doManual = FXMenuCommand.new(menu_pane, "Manual Request.." )

                  doManual.connect(SEL_COMMAND) {
                    if item.data
                    @interface.open_manual_request_editor(item.data)
                    end

                  }
                end
              # submenu = FXMenuPane.new(self) do |domain_menu|

              #   @filtered_domains.each do |domain, filter|
              #     hide_domain = FXMenuCommand.new(domain_menu, "#{domain}" )
              #     hide_domain.connect(SEL_COMMAND) {
              #       @interface.default_settings[:domain_filters].delete(filter)
              #       @filtered_domains.clear
              #       @interface.updateTreeLists
              #     }
              #   end
              # end
              # FXMenuCascade.new(menu_pane, "Unhide Domains", nil, submenu)

              end
              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)

            end
          end
        end
      end

      private

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end
    end
  # namespace end
  end
end
