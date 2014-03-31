# .
# sql_boolean.rb
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
      module Sqlinjection
        
        
        class Sql_boolean < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
            super(project, prefs)
            @info.update(
                         :check_name => 'Boolean SQL-Injection',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_SQL,
            :description => "Checks parameter values for boolean-style SQL-Injection flaws.",   # description of checkfunction
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
            
            measure = "All user input must be escaped and/or filtered thoroughly before the sql statement is put together. Additionally prepared statements should be used."
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "SQL-Injection",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure
            )
            
            @boolean_checks = [ 
            [ ' and 1=1', ' and 1=2'],
            [ '\' and \'1\'=\'1', '\' and \'1\'=\'2'],
            [ '\') and \'1\'=\'1\'(\'', '\') and \'1\'=\'2\'(\'' ],
            [ '\')) and \'1\'=\'1\'((\'', '\')) and \'1\'=\'2\'((\'' ],
            [ '\'))) and \'1\'=\'1\'(((\'', '\'))) and \'1\'=\'2\'(((\'' ], 
            [ ') and \'1\'=\'1\'(', ') and \'1\'=\'2\'(' ],
            [ ')) and \'1\'=\'1\'((', ')) and \'1\'=\'2\'((' ],
            [ '))) and \'1\'=\'1\'(((', '))) and \'1\'=\'2\'(((' ],             
            ]
          end
          
          def generateChecks(chat)
            
            #
            #  Check GET-Parameters
            #
            begin
              urlParmNames(chat).each do |get_parm|
                
                @boolean_checks.each do |check_true, check_false|
                  
                  
                  checker = proc {
                  parm = get_parm.dup
                   check_t = CGI::escape(check_true)
                   check_f = CGI::escape(check_false)
                    
                    begin
                      test_request = nil
                      test_response = nil
                      
                      # first do request double time to check if hashes are the same
                      test = chat.copyRequest
                      value = test.get_parm_value(parm)
                      test_request,test_response = doRequest(test,:default => true)
                    #  puts "test(Request/Response): #{test.object_id}(#{test_request.object_id}/#{test_response.object_id})"
                      text_1, hash_1 =  Watobo::Utils.smartHash(chat.request, test_request, test_response)
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test,:default => true)
                      text_2, hash_2 =  Watobo::Utils.smartHash(chat.request, test_request, test_response)
                    #  puts "test(Request/Response): #{test.object_id}(#{test_request.object_id}/#{test_response.object_id})"
                      
                      if hash_1 == hash_2 then
                        test = chat.copyRequest
                        val = test.get_parm_value(parm)
                        val += check_f
                        test.replace_get_parm(parm, val)
                        
                        test_request,test_response = doRequest(test,:default => true)
                        text_false, hash_false = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                        # check if hash is the same, if yes then this parameter is not good for us
                        if hash_1 != hash_false then
                          
                          test = chat.copyRequest
                          val = test.get_parm_value(parm)
                          val += check_t
                          test.replace_get_parm(parm, val)
                          test_request, test_response = doRequest(test, :default => true)
                          #puts "test(Request/Response): #{test.object_id}(#{test_request.object_id}/#{test_response.object_id})"
                          text_true, hash_true = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                          
                          if hash_true == hash_1 then
                            path = "/" + test_request.path
                           # test_chat = Chat.new(test, test_response,chat.id)
                            addFinding( test_request,test_response,
                            :test_item => parm,
                                       :check_pattern => "#{parm}",
                            :chat => chat,
                            :title => "[#{parm}] - #{path}",
                            :debug => true
                            )                            
                          end                          
                        else
                         # puts "\n! Boolean check not possible on chat #{chat.id}. Get parameter #{parm} is imune :("
                        end
                      else
                       # puts "\n! Boolean check not possible on chat #{chat.id}. Hashes don't match for get parameter #{parm} :("
                      end
                    rescue => bang
                      puts bang
                      raise
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  
                end
                
              end
              
              postParmNames(chat).each do |post_parm|
                
                @boolean_checks.each do |check_true, check_false|
                  
                  checker = proc {
                    begin
                      parm = post_parm.dup
                      check_t = CGI::escape(check_true)
                      check_f = CGI::escape(check_false)
                      test_request = nil
                      test_response = nil
                      
                      # first do request double time to check if hashes are the same
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                      text_1, hash_1 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                      text_2, hash_2 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                      #puts "=== SQL BOOLEAN (#{parm}) ===="
                      #puts "=TEXT_1 (#{parm})\r\n#{text_1}\r\n=HASH_1\r\n#{hash_1}" if parm =~ /button/
                      #puts "=TEXT_2 (#{parm})\r\n#{text_2}\r\n=HASH_2\r\n#{hash_2}" if parm =~ /button/
                      if hash_1 == hash_2 then
                        test = chat.copyRequest
                        val = test.post_parm_value(parm)
                        val += check_f
                       
                        test.replace_post_parm(parm, val)
                        test_request,test_response = doRequest(test, :default => true)
                        text_false, hash_false = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                       # puts "=TEXT_FALSE (#{parm})\r\n#{text_false}\r\n=HASH_FALSE\r\n#{hash_false}" if parm =~ /button/
                                                                        
                                                                        
                        # check if hash is the same, if yes then this parameter is not good for us
                        if hash_1 != hash_false then
                          test = chat.copyRequest
                          val = test.post_parm_value(parm)
                          val += check_t
                          test.replace_post_parm(parm, val)
                          test_request,test_response = doRequest(test, :default => true)
                          text_true, hash_true = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                        #  puts "=TEXT_TRUE (#{parm})\r\n#{text_true}\r\n=HASH_TRUE\r\n#{hash_true}" if parm =~ /button/
                                                
                                                
                        #  if parm =~ /account/ then
                        #    filename = File.join(File.dirname($0), "bc_1.txt")
                        #    puts filename
                        #    fh = File.new(filename, "w")
                        #    fh.puts text_1
                        #    fh.close
                        #    filename = File.join(File.dirname($0), "bc_true.txt")
                        #    puts filename
                        #    fh = File.new(filename, "w")
                        #    
                        #    fh.puts text_true
                        #    fh.close
                        #    
                        #  end
                        
                          if hash_true == hash_1 then
                            puts "!GOTCHA! #{hash_1} / #{hash_true}\r\n=TEXT_1 (#{parm})\r\n#{text_1}\r\n=HASH_1\r\n#{hash_1}\r\n=TEXT_2 (#{parm})\r\n#{text_2}\r\n=HASH_2\r\n#{hash_2}\r\n=TEXT_FALSE (#{parm})\r\n#{text_false}\r\n=HASH_FALSE\r\n#{hash_false}\r\n=TEXT_TRUE (#{parm})\r\n#{text_true}\r\n=HASH_TRUE\r\n#{hash_true}"
                
                            path = "/" + test_request.path
                           # test_chat = Chat.new(test,test_response,chat.id)
                            addFinding(test_request,test_response,
                            :test_item => parm,
                                       :check_pattern => "#{parm}",
                            :chat => chat,
                            :title => "[#{parm}] - #{path}",
                            :debug => true
                            )                            
                          end                          
                        else
                        #  puts "\n! Boolean check not possible on chat #{chat.id}. Postparmeter #{parm} is imune :("
                        end
                      else
                       # puts "\n! Boolean check not possible on chat #{chat.id}. Hashes don't match for post parameter #{parm} :("
                       # fh = File.new("bc_1e.txt", "w")
                       #     fh.puts text_1
                       #     fh.close
                       #     fh = File.new("bc_truee.txt", "w")
                       #     fh.puts text_true
                       #     fh.close
                            
                      end
                    rescue => bang
                      puts bang
                      raise
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  
                end                
              end
            rescue => bang
              puts bang
            end
          end
        end
        # --> eo namespace    
      end
    end
  end
end
