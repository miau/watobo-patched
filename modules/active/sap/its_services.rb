# .
# its_services.rb
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
require 'digest/md5'
require 'digest/sha1'

module Watobo
  module Modules
    module Active
      module Sap
        
        
        class Its_services < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
          
            super(project, prefs)
            
            
            @info.update(
                         :check_name => 'SAP ITS: Default Services',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks SAP ITS System for enabled default services.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9",   # check version
            :check_group => AC_GROUP_SAP
            )
            
            @finding.update(
                            :threat => 'Information Disclosure (and maybe more)',        # thread of vulnerability, e.g. loss of information
            :class => "SAP ITS: Default Services",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
            @its_services = [ 
                  "admin", 
                  "webgui", 
                  "systeminfo",
            ]
          end
          
          def generateChecks(chat)
            
            begin
              
              if chat.request.url =~ /\/wgate\/(\w*\/!?)/ then
                service_name = $1
                @its_services.each do |service|
                  checker = proc{
                    test_request = nil
                    test_response = nil
                    c_service = "#{service.dup}"
                    c_srv_name = "#{service_name}"
                    test = chat.copyRequest
                    test.first.gsub!(c_srv_name, "#{c_service}/!")                
                    
                    test_request,test_response = doRequest(test, :default => true)
                    
                    
                    if test_response.status =~ /200/i then
                      #test_chat = Chat.new(test,test_response,chat.id)
                      addFinding( test_request,test_response,
                      :test_item => chat.request.url,
                                 :check_pattern => "#{c_service}",
                      :proof_pattern => "#{test_response.status}",
                      :chat => chat,
                      :title => c_service
                      )
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                end            
              end
            rescue => bang
              puts bang
              puts "ERROR!! #{Module.nesting[0].name}"
            end
          end
          
        end
        # --> eo namespace    
      end
    end
  end
end
