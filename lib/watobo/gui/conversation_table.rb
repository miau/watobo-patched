# .
# conversation_table.rb
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
    TABLE_COL_METHOD = 0x0001
    TABLE_COL_HOST = 0x0002
    TABLE_COL_PATH = 0x0004
    TABLE_COL_PARMS = 0x0008
    TABLE_COL_STATUS = 0x0010
    TABLE_COL_COOKIE = 0x0020
    TABLE_COL_COMMENT = 0x0040
    TABLE_COL_SSL = 0x0100
    class ConversationTable < FXTable

      attr_accessor :autoscroll
      attr_accessor :url_decode

      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listeners[event] ||= []
        @event_dispatcher_listeners[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          puts "NOTIFY: #{self}(:#{event}) [#{@event_dispatcher_listeners[event].length}]" if $DEBUG
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def num_total
        @current_chat_list.length
      end

      def num_visible
        self.numRows
      end

      def reset_filter
        @filter = {
          :show_scope_only => false,
          :text => '',
          :url => false,
          :request => false,
          :response => false,
          :hide_tested => false,
          :doc_filter => []
        }
      end

      # :show_scope_only => false,
      # :text => '',
      # :url => false,
      # :request => false,
      # :response => false,
      # :hide_tested => false
      def apply_filter(filter={})

        @filter.update filter
        @uniq_chats.clear
        puts @filter.to_yaml if $DEBUG
        update_table
      end

      def chat_visible?(chat)
        begin
        #if @active_project and @active_project.settings[:site_filter]
        #  #puts chat.request.url
        #puts @active_project.settings[:site_filter]
        #  return false if @active_project.settings[:site_filter] != '' and chat.request.url =~ /^http(s)?:\/\/#{Regexp.quote(@active_project.settings[:site_filter])}/
        #  return true
        # end

          if @filter[:unique]
            unless Watobo::Gui.project.nil?
              uniq_hash = Watobo::Gui.project.uniqueRequestHash chat.request
              return false if @uniq_chats.has_key? uniq_hash
              @uniq_chats[uniq_hash] = nil
            end
          end

          if @filter[:show_scope_only]
            unless Watobo::Gui.project.nil?
              return false unless Watobo::Gui.project.siteInScope?(chat.request.site)
            end
          end
          # puts "* passed scope"
          if @filter[:hide_tested]
          return false if chat.tested?
          end
          # puts "* passed hide tested"
          unless @filter[:doc_filter].include?(chat.request.doctype)
            return true if @filter[:text].empty?

            return true if @filter[:url] and chat.request.first =~ /#{@filter[:text]}/i

            return true if @filter[:request] and chat.request.join =~ /#{@filter[:text]}/i

            if chat.response.content_type =~ /(text|javascript|xml)/
              return true if @filter[:response] and chat.response.join.unpack("C*").pack("C*") =~ /#{@filter[:text]}/i
            end

          end
        rescue => bang
          puts "! could not add chat to table !".upcase
          #  puts chat.id
          puts bang
          puts bang.backtrace if $DEBUG
        end
        false
      end

      def showConversation( chat_list = [], prefs = {} )
        clearConversation()
        chat_list.each do |chat|
          addChat(chat, prefs)
        end
        adjustCellWidth()
      end

      def setNewFont(font_type=nil, size=nil)
        begin
          new_size = size.nil? ? GUI_REGULAR_FONT_SIZE : size
          new_font_type = font_type.nil? ? "helvetica" : font_type
          new_font = FXFont.new(getApp(), new_font_type, new_size)
          new_font.create

          self.font = new_font
          self.rowHeader.font = new_font
          self.defRowHeight = new_size+10

          update_table()

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def updateComment(row, comment)
        col = @col_order.index(TABLE_COL_COMMENT)
        self.setItemText(row, col, comment.gsub(/[^[:print:]]/,' '))
      end

      def addChat(chat, *prefs)
        if self.getNumRows <= 0 then
          clearConversation()
        # initColumns()
        end

        @current_chat_list.push chat unless chat.nil?
        if prefs.include? :ignore_filter
          add_chat_row(chat)
          return true
        end
        add_chat_row(chat) if chat_visible?(chat)
        return true

      end

      def initColumns()
        self.setTableSize(0, @columns.length)
        self.visibleRows = 20
        self.visibleColumns = @columns.length

        @columns.each do |type, name|
          index = @col_order.index(type)
          self.setColumnText( index, name )
          self.setColumnIcon(@col_order.index(TABLE_COL_SSL), TBL_ICON_LOCK)# puts self.getItem(@col_order.index(col), 0  ).class.to_s
        end

      end

      def initialize( owner, unused = nil )
        @event_dispatcher_listeners = Hash.new

        super(owner, :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)

        @url_decode = true

        self.setBackColor(FXRGB(255, 255, 255))
        self.setCellColor(0, 0, FXRGB(255, 255, 255))
        self.setCellColor(0, 1, FXRGB(255, 240, 240))
        self.setCellColor(1, 0, FXRGB(240, 255, 240))
        self.setCellColor(1, 1, FXRGB(240, 240, 255))

        reset_filter
        #   FXMAPFUNC(SEL_CLICKED, FXTable::ID_SELECT_CELL, :onSelectCell)
        @current_chat_list = []
        @uniq_chats = Hash.new

        @columns = Hash.new
        @cell_width = Hash.new
        @col_order = []
        @autoscroll = false

        @columns = Hash.new

        @columns[TABLE_COL_METHOD] = "Method"
        @columns[TABLE_COL_HOST] = "Host"
        @columns[TABLE_COL_PATH] = "Path"
        @columns[TABLE_COL_PARMS] = "Parameters"
        @columns[TABLE_COL_STATUS] = "Status"
        @columns[TABLE_COL_COOKIE] = "Set-Cookie"
        @columns[TABLE_COL_COMMENT] = "Comment"
        @columns[TABLE_COL_SSL] = ""

        # initialize columns order
        @col_order = [ TABLE_COL_SSL, TABLE_COL_METHOD, TABLE_COL_HOST, TABLE_COL_PATH, TABLE_COL_PARMS, TABLE_COL_STATUS, TABLE_COL_COOKIE, TABLE_COL_COMMENT ]

        # init cell width
        @cell_width = Hash.new
        @cell_width[TABLE_COL_METHOD] = 50
        @cell_width[TABLE_COL_HOST] = 120
        @cell_width[TABLE_COL_PATH] = 200
        @cell_width[TABLE_COL_PARMS] = 150
        @cell_width[TABLE_COL_STATUS] = 50
        @cell_width[TABLE_COL_COOKIE] = 70
        @cell_width[TABLE_COL_COMMENT] = 100
        @cell_width[TABLE_COL_SSL] = 20

        @cell_width_defaults = Hash.new
        @cell_width_defaults.update YAML.load(YAML.dump(@cell_width))

        @cell_auto_max = 400
        @cell_min_width = 30

        initColumns()

        self.columnHeader.connect(SEL_CHANGED) do |sender, sel, index|
          type = @col_order[index]
          @cell_width[type] = self.getColumnWidth(index)
        end

        self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
          type = @col_order[index]
          column_width = self.getColumnWidth(index)

          new_width = case column_width
          when column_width > @cell_auto_max
            @cell_auto_max
          when ( column_width > @cell_width_defaults[type] )
            @cell_width_defaults[type]
          when @cell_width_defaults[type]
            self.fitColumnsToContents(index)
            w = self.getColumnWidth(index)
            w = @cell_auto_max if self.getColumnWidth(index) > @cell_auto_max
            w = @cell_width_defaults[type] if self.getColumnWidth(index) < @cell_width_defaults[type]
            w
          else
          @cell_width_defaults[type]
          end
          self.setColumnWidth(index, new_width)
          @cell_width[type] = new_width
          self.rowHeaderMode = 0

          adjustCellWidth()
        end

        adjustCellWidth()
      end

      def scrollUp()
        self.makePositionVisible(0, 0)
      end

      def scrollDown()
        self.makePositionVisible(self.numRows-1, 0)
      end

      def clearConversation()
        self.clearItems
        @current_chat_list = []
        initColumns()
        adjustCellWidth()
      end

      private

      def add_chat_row(chat)
        lastRowIndex = self.getNumRows
        self.appendRows(1)

        self.rowHeader.setItemJustify(lastRowIndex, FXHeaderItem::RIGHT)
        self.setRowText(lastRowIndex, chat.id.to_s)

        index = @col_order.index(TABLE_COL_SSL)
        self.setItemIcon(lastRowIndex, index, TBL_ICON_LOCK) if chat.request.is_ssl?

        index = @col_order.index(TABLE_COL_METHOD)

        self.setItemText(lastRowIndex, index, chat.request.method)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_HOST)
        self.setItemText(lastRowIndex, index, chat.request.host)
        self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_PATH)
        self.setItemText(lastRowIndex, index, chat.request.path)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_PARMS)
        ps = ""
        rup = chat.request.urlparms
        unless rup.nil?
        ps << rup
        end     
       
        post_parms_string = ''
        post_parms_string << chat.request.post_parms.join("&")   
        
        if chat.request.method =~ /POST/ and !post_parms_string.empty? then
          ps << "&&" unless ps.empty?
          ps << post_parms_string         
        end
        
        
        parms = ""
        unless ps.nil?
          #   parms = ps[0..50]
          #   parms += "..." if ps.length > 50
          if @url_decode == true
            parms = CGI.unescape(ps).unpack('C*').pack('U*')
          else
          parms = ps
          end
          parms.gsub!(/[^[:print:]]/,'.')

        end

        self.setItemText(lastRowIndex, index, parms)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_STATUS)
        self.setItemText(lastRowIndex, index, chat.response.status)
        self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT

        if chat.response.header_value("set-cookie").first then
          index = @col_order.index(TABLE_COL_COOKIE)
          self.setItemText(lastRowIndex, index, chat.response.header_value("set-cookie").first.chomp)
          self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT
        end

        if chat.comment then
          index = @col_order.index(TABLE_COL_COMMENT)
          comment = chat.comment.split(/\n/).join(" ")
          cc = comment[0..50]
          cc += "..." if comment.length > 50
          self.setItemText(lastRowIndex, index, cc)
          self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT
        end

        self.makePositionVisible(self.numRows-1, 0) if @autoscroll == true
      end

      def update_table()
        self.clearItems
        initColumns()
        adjustCellWidth()
        @current_chat_list.each do |chat|
          add_chat_row(chat) if chat_visible? chat
        end
      end

      def adjustCellWidth()
        begin
          self.rowHeader.width = 40
          #self.fitColumnsToContents(0)
          @cell_width.each do |col, width|
            pos = @col_order.index(col)
            self.setColumnWidth(pos, width)
          end
        rescue => bang
          puts "!!!ERROR: adjustCellWidth"
        end

      end

    end
  end
end
