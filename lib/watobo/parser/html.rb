# .
# html.rb
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
  module Parser
    module HTML
      class Form
        def input_fields(&block)
          if block_given?
            @input_fields.each do |field|
              yield field
            end
          end
          @input_fields
        end

        def initialize(form_css)
          @form = form_css
          @input_fields = []
          @form.css('input').each do |i|
            @input_fields << InputField.new(i)
          end

        end
      end

      class InputField
        attr :id
        attr :value
        attr :name
       # attr :autocomplete
        
        def to_www_form_parm()
          Watobo::WWWFormParameter.new(:name => @name, :value => @value)
        end
        
        def to_url_parm()
          Watobo::UrlParameter.new(:name => @name, :value => @value)
        end
        
        def initialize(input_css)  
          @css = input_css        
              @id = input_css["id"].nil? ? "" : input_css["id"] 
              @value = input_css["value"].nil? ? "" : input_css["value"]
              @name = input_css["name"].nil? ? "" : input_css["name"]  
              #@autocomplete = input_css["autocomplete"]        
        end
        
        def method_missing(name, *args, &block)
          @css[name.to_s].nil? ? "" : input_css[name.to_s]
        end

      end

      class Links

      end
      
      def links(&block)
        
      end
      
      def input_fields(&block)
        fields = []
        forms do |form|
          form.input_fields do |field|
            yield field if block_given?
            fields << field
          end
        end
        fields
      end
      

      def forms(&block)
        fs = []
        doc = Nokogiri::HTML(self.body)
        doc.css('form').each do |f|
          fo = Form.new(f)
          yield fo if block_given?
        end
        fs
      end

    end
  end
end