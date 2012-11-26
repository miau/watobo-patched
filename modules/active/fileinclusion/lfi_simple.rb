# .
# lfi_simple.rb
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
      module Fileinclusion
        
        
        class Lfi_simple < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            @info.update(
                         :check_name => 'Local File Inclusion',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks for parameters, which can lead to local file inclusion.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :check_group => AC_GROUP_FILE_INCLUSION,
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => 'Code Execution or Information Leakage',        # thread of vulnerability, e.g. loss of information
            :class => "Local File Inclusion",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
            @include_checks = [ 
                                ["etc/passwd",'root:[^:]+:\w+:\w+' ],
                                ["etc/passwd%00",'root:[^:]+:\w+:\w+' ],
                                ["boot.ini", Regexp.quote('[boot loader]')],
                                ["boot.ini%00", Regexp.quote('[boot loader]')]
            ]
            
            @updirs = [0,5,10,15,20]
            
          end
          
          def generateChecks(chat)            
            begin 
              @updirs.each do |up|
                @include_checks.each do |file, pattern|
                  urlParmNames(chat).each do |parm|
                    checker = proc{
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      check = "../"*up + file
                      test.replace_get_parm(parm, check)
                      
                      test_request,test_response = doRequest(test)           
                      
                      
                    #  test_chat = Chat.new(test, test_response, chat.id)
                      if test_response.join =~ /(#{pattern})/ # if default db found, check for content
                        match = $1
                        addFinding(test_request,test_response,
                                   :check_pattern => "#{file}",
                                   :test_item => parm,
                        :proof_pattern => "#{match}",
                        :chat => chat,
                        :rating => VULN_RATING_HIGH,
                        :title => "[#{parm}] - #{test_request.file}"
                        )
                      end
                      [ test_request, test_response ]
                    }
                    yield checker
                  end
                  
                  postParmNames(chat).each do |parm|
                    checker = proc{
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      check = "../"*up + file
                      test.replace_post_parm(parm, check)
                      
                      test_request,test_response = doRequest(test) 
                    
                      if test_response.join =~ /(#{pattern})/i # if default db found, check for content
                        match = $1
                        addFinding(test_request,test_response,
                        :test_item => parm,
                                   :check_pattern => "#{file}",
                        :proof_pattern => "#{match}",
                        :chat => chat,
                        :rating => VULN_RATING_HIGH,
                        :title => "[#{parm}] - #{file}"
                        )                        
                      end
                      [ test_request, test_response ]
                    }
                    yield checker
                  end
                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
            end
            
          end
          
        end
        # --> eo namespace    
      end
    end
  end
end
