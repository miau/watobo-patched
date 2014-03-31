# .
# sql_boolean.rb
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
require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Sqlinjection
        
        
        class Sql_boolean < Watobo::ActiveCheck
          
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
                            :class => "SQL-Injection (Boolean)",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
           
            
            @boolean_checks = [ 
            [ '\'--', '\''],
            [ ' or 1=1', ' and 1=2'],
            [ '\' or \'1\'=\'1', '\' and \'1\'=\'2'],
            [ '\') or \'1\'=\'1\'(\'', '\') and \'1\'=\'2\'(\'' ],
            [ '\')) or \'1\'=\'1\'((\'', '\')) and \'1\'=\'2\'((\'' ],
            [ '\'))) or \'1\'=\'1\'(((\'', '\'))) and \'1\'=\'2\'(((\'' ], 
            [ ') or \'1\'=\'1\'(', ') and \'1\'=\'2\'(' ],
            [ ')) or \'1\'=\'1\'((', ')) and \'1\'=\'2\'((' ],
            [ '))) or \'1\'=\'1\'(((', '))) and \'1\'=\'2\'(((' ],
            [ ' and 1=1', ' and 1=2'],
            [ '\' and \'1\'=\'1', '\' and \'1\'=\'2'],
            [ '\') and \'1\'=\'1\'(\'', '\') and \'1\'=\'2\'(\'' ],
            [ '\')) and \'1\'=\'1\'((\'', '\')) and \'1\'=\'2\'((\'' ],
            [ '\'))) and \'1\'=\'1\'(((\'', '\'))) and \'1\'=\'2\'(((\'' ], 
            [ ') and \'1\'=\'1\'(', ') and \'1\'=\'2\'(' ],
            [ ')) and \'1\'=\'1\'((', ')) and \'1\'=\'2\'((' ],
            [ '))) and \'1\'=\'1\'(((', '))) and \'1\'=\'2\'(((' ],                      
            ]
            
            @prefs = [ '', '%']
            @fins = [ '', '--', ';--']
          end
          
          def generateChecks(chat)
            
            #
            #  Check GET-Parameters
            #
            begin
              urlParmNames(chat).each do |get_parm|
                checks = []
                @prefs.each do |p|
                @fins.each do |f|
                  @boolean_checks.each do  |c| 
                    checks << [ p + c[0] + f, p + c[1] +f ]
                  end
                end
                end
                checks.each do |check_true, check_false|
                  checker = proc {
                    begin
                     # puts "TRUE ==> #{check_true}"
                     # puts "FALSE ==> #{check_false}"
                      parm = get_parm.dup
                      check_t = CGI::escape(check_true)
                      check_f = CGI::escape(check_false)
                      test_request = nil
                      test_response = nil
                      
                      # first do request double time to check if hashes are the same
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                      text_1, hash_1 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                     # puts test_response
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                     # puts test_response
                      text_2, hash_2 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                      #puts "=== SQL BOOLEAN (#{parm}) ===="
                      #puts "=TEXT_1 (#{parm})\r\n#{text_1}\r\n=HASH_1\r\n#{hash_1}" if parm =~ /button/
                      #puts "=TEXT_2 (#{parm})\r\n#{text_2}\r\n=HASH_2\r\n#{hash_2}" if parm =~ /button/
                     
                      if hash_1 == hash_2 then
                        test = chat.copyRequest
                        val = test.get_parm_value(parm)
                       # val << "AB" if val.empty?
                        val << check_t
                       
                        test.replace_get_parm(parm, val)
                        true_request,true_response = doRequest(test, :default => true)
                        text_true, hash_true = Watobo::Utils.smartHash(chat.request, true_request, true_response)
                        
                        test = chat.copyRequest
                        val = test.get_parm_value(parm)
                       # val << "AB" if val.empty?
                        val.reverse!
                        val += check_t
                       
                        test.replace_get_parm(parm, val)
                        random_request,random_response = doRequest(test, :default => true)
                        text_random, hash_random = Watobo::Utils.smartHash(chat.request, random_request, random_response)
                        
                        test = chat.copyRequest
                        val = test.get_parm_value(parm)
                        #val << "AB" if val.empty?
                        val += check_f
                       
                        test.replace_get_parm(parm, val)
                        false_request,false_response = doRequest(test, :default => true)
                        text_false, hash_false = Watobo::Utils.smartHash(chat.request, false_request, false_response)
                         
                        unless (hash_true == hash_false) and (hash_true == hash_random) then
                          test = chat.copyRequest
                          val = test.get_parm_value(parm)
                          #val << "AB" if val.empty?
                          val += check_t
                          test.replace_get_parm(parm, val)
                          test_request,test_response = doRequest(test, :default => true)
                          text_true, hash_true = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                        
                          if hash_true == hash_1 or hash_false == hash_1 or hash_true == hash_random or hash_false == hash_random then
                        
                            path = "/" + test_request.path
                           # test_chat = Chat.new(test,test_response,chat.id)
                         #  puts "MATCH !!! #{self.to_s.gsub(/.*::/,'')}"
                            addFinding(test_request,test_response,
                            :test_item => parm,
                                       :check_pattern => "#{parm}",
                            :chat => chat,
                            :title => "[#{parm}] - #{path}",
                            :debug => true
                            )                            
                          end                          
                        else
                          #puts "\n! Boolean check not possible on chat #{chat.id}. URL parmeter #{parm} is imune :("
                          #puts "--- Hashes are equal!"
                          #puts text_true
                          #puts "---"
                          #puts text_false
                          #puts "---"
                          #puts text_random
                          #puts "==="
                        end
                      else
                         puts "\n! Boolean check not possible on chat #{chat.id}. Response differs too much :(" if $DEBUG
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
                checks = []
                @prefs.each do |p|
                @fins.each do |f|
                  @boolean_checks.each do  |c| 
                    checks << [ p + c[0] + f, p + c[1] +f ]
                  end
                end
                end
                checks.each do |check_true, check_false|
                  
                  checker = proc {
                    begin
                     # puts "TRUE ==> #{check_true}"
                     # puts "FALSE ==> #{check_false}"
                      parm = post_parm.dup
                      check_t = CGI::escape(check_true)
                      check_f = CGI::escape(check_false)
                      test_request = nil
                      test_response = nil
                      
                      # first do request double time to check if hashes are the same
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                      text_1, hash_1 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                     # puts test_response
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test, :default => true)
                     # puts test_response
                      text_2, hash_2 = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                      #puts "=== SQL BOOLEAN (#{parm}) ===="
                      #puts "=TEXT_1 (#{parm})\r\n#{text_1}\r\n=HASH_1\r\n#{hash_1}" if parm =~ /button/
                      #puts "=TEXT_2 (#{parm})\r\n#{text_2}\r\n=HASH_2\r\n#{hash_2}" if parm =~ /button/
                     
                      if hash_1 == hash_2 then
                        test = chat.copyRequest
                        val = test.post_parm_value(parm)
                       # val << "AB" if val.empty?
                        val << check_t
                       
                        test.replace_post_parm(parm, val)
                        true_request,true_response = doRequest(test, :default => true)
                        text_true, hash_true = Watobo::Utils.smartHash(chat.request, true_request, true_response)
                        
                        test = chat.copyRequest
                        val = test.post_parm_value(parm)
                       # val << "AB" if val.empty?
                        val.reverse!
                        val += check_t
                       
                        test.replace_post_parm(parm, val)
                        random_request,random_response = doRequest(test, :default => true)
                        text_random, hash_random = Watobo::Utils.smartHash(chat.request, random_request, random_response)
                        
                        test = chat.copyRequest
                        val = test.post_parm_value(parm)
                        #val << "AB" if val.empty?
                        val += check_f
                       
                        test.replace_post_parm(parm, val)
                        false_request,false_response = doRequest(test, :default => true)
                        text_false, hash_false = Watobo::Utils.smartHash(chat.request, false_request, false_response)
                         
                        unless (hash_true == hash_false) and (hash_true == hash_random) then
                          test = chat.copyRequest
                          val = test.post_parm_value(parm)
                          #val << "AB" if val.empty?
                          val += check_t
                          test.replace_post_parm(parm, val)
                          test_request,test_response = doRequest(test, :default => true)
                          text_true, hash_true = Watobo::Utils.smartHash(chat.request, test_request, test_response)
                        
                          if hash_true == hash_1 or hash_false == hash_1 or hash_true == hash_random or hash_false == hash_random then
                        
                            path = "/" + test_request.path
                           # test_chat = Chat.new(test,test_response,chat.id)
                          # puts "MATCH !!! #{self.to_s.gsub(/.*::/,'')}"
                            addFinding(test_request,test_response,
                            :test_item => parm,
                                       :check_pattern => "#{parm}",
                            :chat => chat,
                            :title => "[#{parm}] - #{path}",
                            :debug => true
                            )                            
                          end                          
                        else
                          #puts "\n! Boolean check not possible on chat #{chat.id}. URL parmeter #{parm} is imune :("
                          #puts "--- Hashes are equal!"
                          #puts text_true
                          #puts "---"
                          #puts text_false
                          #puts "---"
                          #puts text_random
                          #puts "==="
                        end
                      else
                         puts "\n! Boolean check not possible on chat #{chat.id}. Response differs too much :(" if $DEBUG
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
