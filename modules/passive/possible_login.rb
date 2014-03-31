# .
# possible_login.rb
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
      
      
      class Possible_login < Watobo::PassiveCheck
        
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Detect Logins',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detect possible and also unencrypted logins.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'If login credentials are sent over an unencrypted channel, an attacker may eavesdrop these information.'        # thread of vulnerability, e.g. loss of information
          
          )
          
          @check_name = "Detect Logins"
          @description = "maybe usefull?"
          
          
          @possible_login_patterns=%w[ (username) (password) (passwd) (pass) (uid) (userid) ]
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            # all_parms = chat.request.post_parms
            all_parms = chat.request.parameters(:data, :url)
            return true if all_parms.empty?
              # puts all_parms
            #  resource = "/" + chat.request.resource
              all_parms.each do |parm|
                @possible_login_patterns.each do |pattern|
                  #  puts "Testing pattern #{pattern} on postparms\r\n#{parm}"
                  if parm.name =~ /#{pattern}/i
                    match = $1
                    
                    addFinding(
                               :class => "Logins",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                    :type => FINDING_TYPE_HINT,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
                    :check_pattern => "#{parm}", 
                    :chat => chat,
                    :title => "#{chat.request.path_ext}"
                    #:debug => true
                    )
                    # check for unecrypted transfer
                    
                    if not chat.request.proto =~ /https/i
                      addFinding(
                                 :class => "Unencrypted Logins",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                      :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
                      :check_pattern => "#{chat.request.proto}",
                      :chat => chat,
                      :rating => VULN_RATING_HIGH,
                      :title => "#{chat.request.path_ext}"
                     # :debug => true
                      )
                    end
                    
                    # also check if session id has been redefined
                    puts "* check session managment"
                    old_cookies = chat.request.cookies.select do |rc|
                      cookie_old = true
                      chat.response.new_cookies do |nc|
                         cookie_old = false unless rc.value == nc.value
                         #puts ":#{rc} - #{nc.name} - #{cookie_old}"                        
                      end
                      puts ":#{rc} >> #{cookie_old}"     
                      cookie_old
                    end
                    puts "old cookies (#{old_cookies.length})"
                    old_cookies.map do |c|
                      addFinding(
                                 :class => "Session Managment",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                      :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
                      :check_pattern => "#{c}",
                      :chat => chat,
                      :rating => VULN_RATING_MEDIUM,
                      :title => "#{chat.request.path_ext}",
                      :threat => "Session Cookie has not been renewed after login. Session-Fixation attacks may be possible."
                     # :debug => true
                      )
                    end
                    
                    return true
                  end               
              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
        
      end
    end
  end
end
