# .
# sqli_error.rb
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
  module Modules
    module Active
      module Sqlinjection
        
        
        class Sqli_error < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
            super(project, prefs)
            @info.update(
                         :check_name => 'Error-based SQL-Injection',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_SQL,
            :description => "Check every parameter for SQL-Injection flaws. The detection is based on error messages of the database.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            threat =<<'EOF'
SQL Injection is an attack technique used to exploit applications that construct SQL statements from user-supplied input. 
When successful, the attacker is able to change the logic of SQL statements executed against the database.
Structured Query Language (SQL) is a specialized programming language for sending queries to databases. 
The SQL programming language is both an ANSI and an ISO standard, though many database products supporting SQL do so with 
proprietary extensions to the standard language. Applications often use user-supplied data to create SQL statements. 
If an application fails to properly construct SQL statements it is possible for an attacker to alter the statement structure 
and execute unplanned and potentially hostile commands. When such commands are executed, they do so under the context of the user 
specified by the application executing the statement. This capability allows attackers to gain control of all database resources 
accessible by that user, up to and including the ability to execute commands on the hosting system.

Source: http://projects.webappsec.org/SQL-Injection
EOF
            #
            measure = "All user input must be escaped and/or filtered thoroughly before the sql statement is put together. Additionally prepared statements should be used."
            
            @finding.update(
                            :threat => threat,        # threat of vulnerability, e.g. loss of information
                            :class => "Error-based SQL-Injection",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure 
            )
            
            @sql_checks=[
            "';--",
            "'",  
            ]
            
            @sql_patterns = [ 
                "OleDBException",
                "SQL Server",            
                "Microsoft OLE DB Provider",
                "Incorrect syntax near",
                "ADODB",
                "DB2 SQL",
                "DB2.*SQL\d+N",
                "ODBC Microsoft Access Driver",
                "(PLS|ORA).[0-9]{2,}",
                "PostgreSQL query",
                "error in your SQL syntax"
               
            ]
            
          end
          
          def generateChecks(chat)
            
            begin
              urlParmNames(chat).each do |parm|
                # puts "#{Module.nesting[0].name}: run check on chat-id (#{chat.id}) with parm (#{parm})"
                #@sql_checks.each do |check, pattern|
                test_values = []
                @sql_checks.each do |check|
                  test_values << check
                  test_values << "#{chat.request.get_parm_value(parm)}#{check}"
                  test_values << "#{check}#{chat.request.get_parm_value(parm)}"
                end
                test_values.each do |check|
                  checker = proc {
                    
                    test_request = nil
                    test_response = nil
                    # IMPORTANT!!!
                    # use prepareRequest(chat) for cloning the original request 
                    test = chat.copyRequest
                    test_parm = "#{parm.clone}"
                    # modify the test request
                    test.replace_get_parm(test_parm, check)
                    # fire it up!
                    #puts req_copy
                    test_request,test_response = doRequest(test)
                    
                    # puts test_response
                    # verify response
                    match = nil
                    @sql_patterns.each do |pattern|
                      if test_response.join =~ /(#{pattern})/i
                        match = $1
                       # test_chat = Chat.new(test,test_response,chat.id)
                      #  path = "/" + test_request.path_ext
                        addFinding(test_request,test_response,
                            :test_item => parm,
                                   :check_pattern => "#{check}", 
                        :proof_pattern => "#{match}",
                        :chat => chat,
                        :title => "[#{test_parm}] - #{test_request.path}"
                        )
                      end
                      
                    end
                    
                    [ test_request, test_response ]
                  }
                  yield checker
                end            
              end
              
              
              #
              #  Check POST-Parameters
              #           
              
              postParmNames(chat).each do |parm|
                #puts "#{chat.id}: run check on post parm #{parm}"
                test_values = []
                @sql_checks.each do |check|
                  test_values << check
                  test_values << "#{chat.request.post_parm_value(parm)}#{check}"
                  test_values << "#{check}#{chat.request.post_parm_value(parm)}"
                end
                test_values.each do |check|
                  checker = proc {
                    test_request = nil
                    test_response = nil
                    # IMPORTANT!!!
                    # use prepareRequest(chat) for cloning the original request 
                    test = chat.copyRequest
                    test_parm = "#{parm.clone}"
                    
                    
                    # modify the test request
                    test.replace_post_parm(test_parm,check)
                    # puts test.last
                    # fire it up!
                    #puts req_copy
                    test_request,test_response = doRequest(test)
                    
                    # puts test_response
                    # verify response
                    match = nil
                    @sql_patterns.each do |pattern|
                      if test_response.join =~ /(#{pattern})/i
                        match = $1
                        # puts "found xss (post)"
                       # test_chat = Chat.new(test,test_response,chat.id)
                        #resource = "/" + test_request.resource
                        addFinding(test_request,test_response,
                            :test_item => parm,
                                   :check_pattern => "#{check}", 
                        :proof_pattern => "#{match}",
                        :chat => chat,
                        :title => "[#{test_parm}] - #{test_request.path}"
                        )
                      end
                      
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  
                end
              end            
            rescue => bang
              puts bang
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
            end
          end
          
        end
        
      end
    end
  end
end
