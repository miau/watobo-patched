# .
# http_methods.rb
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
    module Active
      module Discovery
        
        
        class Http_methods < Watobo::ActiveCheck
           @@tested_directories = []
          
            @info.update(
                         :check_name => 'HTTP Methods',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks for supported HTTP Methods.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            @finding.update(
                            :threat => 'Some HTTP methods can be exploited by an attacker to compromise the system.',        # thread of vulnerability, e.g. loss of information
            :class => "HTTP Methods",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
           
          def initialize(project, prefs={})
            @project = project
            super(project, prefs)
            
            
            @dummy_element = "WATOBO"
            
            @not_allowed_response = [ "UNAUTHORIZED", "NOT IMPLEMENTED", "NOT ALLOWED", "NOT SUPPORTED", "FORBIDDEN", "BAD REQUEST", "302"]
            
            @test_methods = %w[ PROPFIND PROPPATCH COPY UNLOCK MKCOL ] + # web_dav_methods - DELETE is too dangerous here
                          %w[ OPTIONS TRACE ]+ # common but unwanted methods
                          %w[ TRACK DEBUG ] +             # IIS methods 
                          %w[ CHECKOUT SHOWMETHOD LINK CHECKIN TEXTSEARCH SPACEJUMP SEARCH REPLY]+ # http://www.w3.org/Protocols/HTTP/Methods.html
                          %w[ VERSION_CONTROL CHECKIN UNCHECKOUT PATCH ] # eclipse_methods
            @test_methods = %w[ TRACE ]
          end
          
          def reset()
            @@tested_directories.clear
          end
          
          def generateChecks(chat)
            
            begin
               unless @@tested_directories.include?(chat.request.dir) then
                @@tested_directories.push chat.request.dir
                @test_methods.each do |method|
                  #sleep(1)
                  checker = proc{
                  begin
                    result = nil
                    test_request = nil
                    test_response = nil
                    test_method = "#{method}"
                    # !!! ATTENTION !!!
                    # MAKE COPY BEFORE MODIFIYING REQUEST 
                   
                    test_request = chat.copyRequest
                   
                    test_request.replaceMethod(test_method)
                   
                    result_request, result_response = doRequest(test_request, :default => true)
                    is_vuln = true
                    if result_response.status then                      
                      @not_allowed_response.each do |nar|
                        if result_response.status =~ /#{nar}/i then 
                          is_vuln = false                        
                        end
                      end
                      
                      if is_vuln == true then
                        addFinding( result_request, result_response,
                                   :check_pattern => "#{test_method}",
                        :proof_pattern => "#{result_response.status}",
                        :test_item => chat.request.dir,
                        :chat => chat,
                        :title => "#{test_method}"
                        #:debug => true
                        )
                      end
                    end
                    result = [ result_request, result_response ] 
                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                    result = [ nil, nil ]
                    end
                    result
                  }
                  yield checker
                end    
                
                
              end
              
            end            
          rescue => bang
            
            puts "ERROR!! #{Module.nesting[0].name} "
            puts "chatid: #{chat.id}"
            puts bang
            puts 
            
          end
          
        end
        
      end
    end
  end
end
