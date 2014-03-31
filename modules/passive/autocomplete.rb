# .
# autocomplete.rb
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
      
      
      class Autocomplete < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Password AutoComplete',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks Password Fields For AutoCompletion",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Password values may be stored on the local filesystem.',        # thread of vulnerability, e.g. loss of information
          :class => "Password Autocompletion",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
           :rating => VULN_RATING_LOW,
          :measure => "The form field should have an attribute autocomplete=\"off\"" 
          )
        end
        
        def do_test(chat)
          begin
                       
           if chat.response.respond_to? :input_fields     
             chat.response.input_fields do |f|
            
              ac = f.autocomplete.nil? ? "" : f.autocomplete
              
              if f.type =~ /password/i and ( ac =~ /off/i or ac.empty? )          
              addFinding(  
                         :proof_pattern => "input[^>]*type=[^>=]*password.*>{1}", 
              :title => "#{chat.request.file}",
              :chat => chat
              )  
              end
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return false
        end
      end
      
    end
  end
end
