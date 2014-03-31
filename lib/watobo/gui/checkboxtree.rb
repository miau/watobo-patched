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
module Watobo
  module Gui
    class CheckBoxTreeItem < FXTreeItem
      attr_accessor :checked
      
      include Watobo::Gui::Icons
      def initialize(text, checked, data)
        @checked = checked
        icon = ICON_CB_CHECKED
        icon = ICON_CB_UNCHECKED if not checked
        super(text, icon, icon, data)
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
      def createTree(elements)
        self.clearItems()
        elements.each do |e|
          
          # puts icon.class.to_s
          node = nil
          levels = e[:name].split('|')
          puts "Processing: #{e[:name]} > #{e[:data].class}" if $DEBUG
          levels.each do |l|
            
            item = self.findItem(l, node, SEARCH_FORWARD|SEARCH_IGNORECASE)
            
            if item.nil? then
              new_item = CheckBoxTreeItem.new(l, e[:enabled], nil)
              # item = self.appendItem(node, l, ICON_CB_CHECKED, ICON_CB_CHECKED) 
              item = self.appendItem(node, new_item)
              if e[:enabled] then
                self.openItem(item, false)
              else
                self.closeItem(item, false)
              end
            end
            node = item
            if l == levels.last then
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
      
      def toggleState(item)
        #  data = self.getItemData(item)
        #  if data[:enabled] then
        if item.checked then
          uncheckItem(item)
        else
          checkItem(item)
        end
      end
      
      def uncheckItem(item)
        begin
          #data = self.getItemData(item)
          #data[:enabled]= false
          item.checked = false        
          self.setItemOpenIcon(item, ICON_CB_UNCHECKED)
          self.setItemClosedIcon(item, ICON_CB_UNCHECKED)
          #puts item.data.class
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
        
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
      
      def checkItem(item)
        begin
          #data = self.getItemData(item)
          #data[:enabled] = true
          item.checked = true
          self.setItemClosedIcon(item, ICON_CB_CHECKED)
          self.setItemOpenIcon(item, ICON_CB_CHECKED)
          # puts item.data.class
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
      end
      
      def uncheckAllChildren(parent)
        parent.each do |child|
          uncheckItem(child)
        end
      end
      
      def checkAllChildren(parent)
        parent.each do |child|
          checkItem(child)
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
            toggleState(item)
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
