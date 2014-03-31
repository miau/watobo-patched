# .
# checks_policy_frame.rb
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
    class ChecksPolicyFrame < FXVerticalFrame
      attr :policy_name
      def onPolicyChanged(sender, sel, item)
        @policy_name = @policyCombo.getItemText(@policyCombo.currentItem)
        policy = @policyCombo.getItemData(@policyCombo.currentItem)
        applyPolicy(policy)
      end

      def isElementChecked(data)
        item = @tree.findItemByData(data)
        item.checked
      end

      def applyPolicy(policy)
        return false if policy.nil?
        tree_elements = []
        @checks.each do |check|
          status = true
          begin
            status = policy[check.class.to_s]
          rescue
          puts "unknown policy or unknown test [#{@policy}] - [#{check.class.to_s}"
          end
          a = {
            :name => "#{check.info[:check_group]}|#{check.info[:check_name]}",
            :enabled => status,
            :data => check
          }
          tree_elements.push a
        end

        showTree(tree_elements)
      end

      def showInfo(check)

      end

      def showTree(elements)
        @tree.createTree(elements)
      end

      def getSelectedModules()
        sel = @tree.getCheckedData
      #sel.map { |i| p i.class }
      end

      def initialize(parent, checks, policy)
        # Invoke base class initialize function first
        super(parent, :opts => LAYOUT_FILL_X| LAYOUT_FILL_Y, :padding => 0)

        @checks = checks
        @policy_list = policy.is_a?(Hash) ? policy : default_policy(checks)         # policy settings

        policy_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        policy_name = @policy_list[:default_policy] if @policy_list.has_key? :default_policy
        @current_policy = @policy_list[policy_name] if @policy_list.has_key? policy_name

        policy_count = ( @policy_list.is_a? Hash ) ? @policy_list.length-1 : 0

        @policyCombo = FXComboBox.new(policy_frame, policy_count, nil, 0,
        COMBOBOX_INSERT_LAST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

        @policyCombo.numVisible = policy_count
        @policyCombo.connect(SEL_COMMAND, method(:onPolicyChanged))

        tree_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        @tree = CheckBoxTreeList.new(tree_frame)

        if @policy_list
          @policy_list.each do |pname, p|
            next if pname.is_a? Symbol
            @policyCombo.appendItem(pname, p)
          end
          # select policy
          index = @policyCombo.findItem(policy_name)
          if index >= 0 then
          @policyCombo.setCurrentItem(index)
          end
        applyPolicy(@current_policy)
        end
      end

      private

      def default_policy(checks)
        @policy_list = Hash.new
        @policy_list[:default_policy] = 'default'
        dp = @policy_list['default'] = Hash.new
        checks.each do |ac|
          dp[ac.class.to_s] = false
        end
        @current_policy = dp
        @policy_list
      end
    end
  #--
  end
end
