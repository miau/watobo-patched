# .
# redirectionz.rb
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
      class Redirectionz < Watobo::PassiveCheck
        
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Redirections By Value',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks if parameter values are used in location header.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Redirect functionalities can be exploited by an attacker redirect a user to an malicious site (Drive By Attacks).',        # thread of vulnerability, e.g. loss of information
          :class => "Redirect Parameters",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
         
        end
        
        def showError(chatid, message)
          puts "!!! Error"  
          puts "Chat: [#{chatid}]"
          puts message
        end
        
        def do_test(chat)
          begin
            chat.request.get_parm_names.each do |parm|
              parm_value=Regexp.quote(chat.request.get_parm_value(parm))
              if parm_value.length > 5 then # check for minimum parameter length (False Positive Reduction)
                chat.response.headers.each do |header|
                  if header =~ /Location.*#{parm_value}.*/i then
                    addFinding(
                                :check_pattern => "#{parm_value}", 
                                :proof_pattern => "#{parm_value}",
                                :chat=>chat,
                                            :title => parm_value
                                )
                  end
                end
              end
            end 
            
            return if chat.request.content_type =~ /multipart/i
            #puts ""
            chat.request.post_parm_names.each do |parm|              
               parm_value=chat.request.post_parm_value(parm)
               if parm_value.length > 5 then # check for minimum parameter length (False Positive Reduction)
                  chat.response.headers.each do |header|                
                    if header =~ /Location.*#{parm_value}.*/i  then
                      addFinding(
                                :check_pattern => "#{parm_value}", 
                                :proof_pattern => "#{parm_value}",
                                :chat=>chat,
                                            :title => parm_value
                                )                  
                    end
                  end
                end
              end
               
          rescue => bang
            # raise
            showError(chat.id, bang)
          end
        end
        
      end
    end
  end
end
