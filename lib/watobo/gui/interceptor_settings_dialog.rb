# .
# interceptor_settings_dialog.rb
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
    
    class InterceptorSettingsFrame < FXVerticalFrame
      
      def getSettings()
        settings = Hash.new
        settings[:port] = @port_dt.value
       
        
        
        dummy = []
        @ct_list.each do |nup|
          dummy.push nup.data
        end
        settings[:pass_through] = {
        :content_types => dummy,
        :content_length => @content_length_dt.value
        }
        
        return settings
      end
      
      def addItem(list_box, item)   
        if item != "" then
          list_item = list_box.appendItem("#{item}")
          list_box.setItemData(list_item, item)
          list_box.sortItems()        
        end
      end
      
      def removePattern(list_box)
        index = list_box.currentItem
        if  index >= 0
          list_box.removeItem(index)
        end
      end
      
      def initialize(owner, opts)        
        super(owner, opts)
        
        #@settings = interceptor_settings
        scroller = FXScrollWindow.new(self, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_area = FXVerticalFrame.new(scroller, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        gbox = FXGroupBox.new(scroll_area, "Listening Port", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        gbox_frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_SIDE_TOP|PACK_UNIFORM_WIDTH)
       
        frame = FXHorizontalFrame.new(gbox_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Listen Port:")
        @port_dt = FXDataTarget.new(0)
        #@port_dt.value = @settings[:port]
        @port_dt.value = Watobo::Conf::Interceptor.port
        lport = FXTextField.new(frame, 5, @port_dt, FXDataTarget::ID_VALUE, :opts => JUSTIFY_RIGHT|FRAME_GROOVE|FRAME_SUNKEN)
        lport.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
       
        gbframe = FXGroupBox.new(scroll_area, "Pass-Through Content-Length", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Define Content-Length threshold for Pass-Through. Responses which Content-Length exceed this size will be forwarded."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(input_frame, "Max. Content-Length:")
        @content_length_dt = FXDataTarget.new('')
        #@content_length_dt.value = @settings[:pass_through][:content_length]
        @content_length_dt.value = Watobo::Conf::Interceptor.pass_through[:content_length]
        content_length_field = FXTextField.new(input_frame, 7, :target => @content_length_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
      content_length_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
       
        
        gbframe = FXGroupBox.new(scroll_area, "Pass-Through Content-Types", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Define Content-Types for Pass-Through. Responses which are forwarded will not be inspected by Passive-Checks. So you only should define Content-Types which in general contain binary data."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @ct_dt = FXDataTarget.new('')
        @ct_field = FXTextField.new(input_frame, 20, :target => @ct_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_ct_btn = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @add_ct_btn = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @ct_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @ct_list.numVisible = 5
        
        @ct_list.connect(SEL_COMMAND){ |sender, sel, item|
          @ct_dt.value = sender.getItemText(item)
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
       # @settings[:pass_through][:content_types].each do |nup|
        Watobo::Conf::Interceptor.pass_through[:content_types].each do |nup|
          addItem(@ct_list, nup)
        end
        
        @rem_ct_btn.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@ct_list) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @add_ct_btn.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@ct_list, @ct_dt.value) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @ct_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@ct_list, @ct_dt.value) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
      end
      
    end
    
    #
    # Class: SelectNonUniqueParmsDialog
    #
    class InterceptorSettingsDialog < FXDialogBox
      
      include Responder
      attr :interceptor_settings
      
      
      def onAccept(sender, sel, event)
        
        @interceptor_settings = @interceptorSettingsFrame.getSettings()
        
        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end
      
      
      def initialize(owner)
        super(owner, "Interceptor Settings", DECOR_TITLE|DECOR_BORDER, :width => 400, :height => 500)
        #@interceptor_settings = interceptor_settings
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        
        
        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        #  puts "create scopeframe with scope:"
        # @project.scope
        # @defineScopeFrame = DefineScopeFrame.new(base_frame, @project.listSites(), YAML.load(YAML.dump(@project.scope)), prefs)
        @interceptorSettingsFrame = InterceptorSettingsFrame.new(base_frame, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        buttons_frame = FXHorizontalFrame.new(base_frame,
                                              :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        
        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
          #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end 
        
        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        
      end
    end
  end
end


if __FILE__ == $0
  # TODO Generated stub
end
