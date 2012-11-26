# .
# its_service_parameter.rb
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
        
        
        class Its_service_parameter < Watobo::ActiveCheck
          
          def initialize(project,prefs={})
           
            super(project, prefs)
            
            
            @info.update(
                         :check_name => 'SAP ITS: Service Parameters',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks SAP ITS services for default parameters.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9",   # check version
            :check_group => AC_GROUP_SAP
            )
            
            @finding.update(
                            :threat => 'Information Disclosure (and maybe more)',        # thread of vulnerability, e.g. loss of information
            :class => "SAP ITS: Service Parameters",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
            @default_service_parameters = [
            ["~command","AgateInstallCheck"],
            ["~runtimeMode", "DM"], # Development Mode vs PM (Production Mode)
            ["~forcetarget", "sap.com"], # forcetarget only in old (maybe buggy) its-systems supported
            ["~exitURL", "www.sap.com"], # exitURL only in old (maybe buggy) its-systems supported
            ]
            
          end
          
          def generateChecks(chat)
            
            begin
              
              if chat.request.url =~ /\/wgate\/(\w*)\/!?/ then
                @default_service_parameters.each do |sp, val|
                  checker = proc{
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest
                    service = "#{sp.dup}"
                    sparm = "#{val.dup}"
                    
                    test.add_get_parm(service, sparm)
                    
                    test_request,test_response = doRequest(test,:default => true)
                    
                    if test_response.status =~ /200/i then
                     # test_chat = Chat.new(test,test_response,chat.id)
                      addFinding( test_request,test_response,
                      :test_item => chat.request.url,
                                 :check_pattern => "#{sparm}",
                      :proof_pattern => "#{test_response.status}",
                      :chat => chat,
                      :title => service
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
