# .
# checkboxtree.rb
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
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  $: << inc_path

  require 'watobo'
  require 'watobo/gui'

  require 'fox16'

  include Fox
  include Watobo::Constants

end

module Watobo
  module Gui
    class CheckBoxTreeItem < FXTreeItem
      attr_accessor :checked

      include Watobo::Gui::Icons
      def check
        begin
          @checked = true
          self.setOpenIcon(ICON_CB_CHECKED)
          self.setClosedIcon(ICON_CB_CHECKED)
          # opened = true
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
      end

      def uncheck
        begin
          @checked = false
          self.setOpenIcon(ICON_CB_UNCHECKED)
          self.setClosedIcon(ICON_CB_UNCHECKED)
          #opened = false
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
      end

      def toggle
        if @checked
          uncheck
        else
          check
        end
      end

      def initialize(item_text, item_status, item_data)
        super item_text
        @checked = item_status
        #icon = ICON_CB_CHECKED
        #icon = ICON_CB_UNCHECKED if not status
        #super(text, icon, icon, data)
        #   data = item_data
        if @checked
          check
        else
          uncheck
        end
      end
    end

    class CheckBoxTreeList < FXTreeList
      include Watobo::Gui::Icons
      #------------------------------
      # C R E A T E T R E E
      #------------------------------
      # elements[] = [{
      #                   :name => element_name, number of subtrees controlled via pipe-char, e.g. <level1>|<level2>|item
      #                   :enabled => true|false,
      #                   :data => object|string|...
      #                   }, {..} ]
      def elements=(elements)
        self.clearItems()
        elements.each do |e|

        # puts icon.class.to_s
          node = nil
          levels = e[:name].split('|')
        #  puts "Processing: #{e[:name]} > #{e[:data].class}" if $DEBUG
          levels.each_with_index do |l,i|
            #puts "#{l} - #{l.class}"
            item = self.findItem(l, node, SEARCH_FORWARD|SEARCH_IGNORECASE)

            if item.nil? then
              # new_item = CheckBoxTreeItem.new(l, e[:enabled], nil)
              new_item = CheckBoxTreeItem.new(l, e[:enabled], :none)
            # item = self.appendItem(node, l, ICON_CB_CHECKED, ICON_CB_CHECKED)
            item = self.appendItem(node, new_item)
            #  if e[:enabled] then
            #    self.openItem(item, false)
            #  else
            #    self.closeItem(item, false)
            #  end
            end
            node = item
            if i == levels.length-1 then
              self.setItemData(item, e[:data])
              updateParent(item)
            end

          end
        end
      end

      def updateParent(child)
        parent = child.parent
        # count enabled childs
        return false if parent.nil?
        ec = 0
        parent.each do |item|
        #data = self.getItemData(item)
        #ec += 1 if data[:enabled]
          ec += 1 if item.checked
        end
        if ec == 0 then

          # puts "no childs selected"
          icon = ICON_CB_UNCHECKED
          self.setItemData(parent, :none)
        elsif  ec < parent.numChildren  then
          # puts "not all childs are selected"
          icon = ICON_CB_CHECKED_ORANGE
          self.setItemData(parent, :partly)
        else

        # puts "all childs have been selected"
          icon =   ICON_CB_CHECKED
          self.setItemData(parent, :all)
        end
        self.setItemOpenIcon(parent, icon)
        self.setItemClosedIcon(parent, icon)
      end

     def getCheckedData(item = nil, data = nil)
        data = [] if !data
        item = self if !item
        item.each do |c|
          getCheckedData(c, data) if c.numChildren > 0
          data.push c.data if self.itemLeaf?(c) and c.checked
        end
        data
      end

      def checkAll
        self.each do |r|
          r.check
          setItemData(r,:all)
          r.each do |c|
            c.check
          end
          self.update
        # checkAllChildren(r)
        #   openItem(child, true)
        end
      end

      def uncheckAll
        self.each do |r|
        # uncheckItem(r)
          r.uncheck
          setItemData(r,:none)
          r.each do |c|
            c.uncheck
          end
          #uncheckAllChildren(r)
          self.update
        end
      end

     
      def uncheckAllChildren(parent)
        parent.each do |child|
        #uncheckItem(child)
          child.uncheck
        end
      end

      def checkAllChildren(parent)
        parent.each do |child|
        #checkItem(child)
          child.check

        end
      end

      def initialize(parent)

        @parent = parent
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|
        TREELIST_SHOWS_LINES|
        TREELIST_SHOWS_BOXES|
        TREELIST_ROOT_BOXES|
        #TREELIST_EXTENDEDSELECT|
        TREELIST_MULTIPLESELECT
        )
        #LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT

        self.connect(SEL_COMMAND) do |sender, sel, item|
          if $DEBUG
            puts "Selected Item: #{item}"
            if item.parent
              puts "Member Of: #{item.parent}"
              puts "Has Brothers: #{item.parent.numChildren}"
            end
          end

          if self.itemLeaf?(item) then
            #toggleState(item)
            item.toggle
            updateParent(item)
          else
            data = self.getItemData(item)

            new_state = case data
            when :partly
              #  puts data
              icon = ICON_CB_UNCHECKED
              uncheckAllChildren(item)
              :none
            when :none
              #  puts data
              icon = ICON_CB_CHECKED
              checkAllChildren(item)
              :all
            when :all
              # puts data
              icon = ICON_CB_UNCHECKED
              uncheckAllChildren(item)
              :none
            end

          self.setItemData(item, new_state)
          self.setItemClosedIcon(item, icon)
          self.setItemOpenIcon(item, icon)
          end

          self.killSelection()
        end

      end
    end
  #--
  end
end

##########################

if $0 == __FILE__
  module Watobo
    module Gui

      @application ||= FXApp.new('LayoutTester', 'FoxTest')
      class TestGui < FXMainWindow
        class TreeDlg < FXDialogBox

          include Responder
          def initialize(parent, project=nil, prefs={} )
            super(parent, "CheckBox Dialog", DECOR_ALL, :width => 300, :height => 400)
            FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
            frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
            elements = []
            num_root_nodes = 4
            max_child_nodes = 4
            num_root_nodes.times do |ri|
              max_child_nodes.times do |si|
                name = "root#{ri}|sub#{si}"
                data = name + "-data"
                e = { :name => name, :enabled => false, :data => data }
                elements << e
              end
            end
            @cbtree = CheckBoxTreeList.new(frame)
            @cbtree.elements = elements

          end
          private

          def onAccept(sender, sel, event)
            puts "#{self} closed"

            getApp().stopModal(self, 1)
            self.hide()
            return 1
          end
        end

        def leave
          d = @cbtree.getCheckedData
          puts d.class
          puts d
          exit
        end

        def initialize(app)
          # Call base class initializer first
          super(app, "Test Application", :width => 800, :height => 600)
          frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

          elements = []
          num_root_nodes = 4
          max_child_nodes = 4
          num_root_nodes.times do |ri|
            max_child_nodes.times do |si|
              name = "root#{ri}|sub#{si}"
              data = name + "-data"
              e = { :name => name, :enabled => false, :data => data }
              elements << e
            end
          end

          @cbtree = CheckBoxTreeList.new(frame)
          @cbtree.elements = elements

          FXButton.new(frame, "Select All",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){ @cbtree.checkAll }
          FXButton.new(frame, "Deselect All",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){ @cbtree.uncheckAll }

          FXButton.new(frame, "Open TreeDialog",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){
            dlg = TreeDlg.new(self)
            if dlg.execute != 0 then
              puts "* Dialog Finished"
            else
              puts "Dialog Canceled"
            end
          }

          FXButton.new(frame, "Exit",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){ leave }
        end

        def create
          super                  # Create the windows
          show(PLACEMENT_SCREEN) # Make the main window appear
        end
      end
      #  application = FXApp.new('LayoutTester', 'FoxTest')
      TestGui.new(@application)
      @application.create
      @application.run

    end
  end
end