# .
# hidden_fields.rb
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
  module Modules
    module Passive
      
      
      class Hidden_fields < Watobo::PassiveCheck
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Hidden Fields',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all hidden fields",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Hidden field parameters sometimes are accepted as input variables.',        # thread of vulnerability, e.g. loss of information
          :class => "Hidden Fields",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "N/A" 
          )
         

        end
        
        def do_test(chat)
          begin
            
            if chat.response.content_type =~ /(text|script)/ and chat.response.status !~ /404/ and chat.response.has_body? then
              doc = Nokogiri::HTML(chat.response.body)
              doc.xpath('//input[@type="hidden"]').each do |i|
                          addFinding(  
                                       :proof_pattern => 'input.*=.{1,3}hidden', 
                                       :title => "#{i[:name]}",
                                       :chat => chat
                          )  
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end
    end
  end
end
