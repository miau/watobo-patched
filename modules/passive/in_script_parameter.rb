# .
# in_script_parameter.rb
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
require 'cgi'
module Watobo
  module Modules
    module Passive
      
      
      class In_script_parameter < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Parameters in Script',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks if parameter values are used within script-tags.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Parameter value may be exploitable for XSS.',        # thread of vulnerability, e.g. loss of information
          :class => "Script-Parameters",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
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
            parm_values = []
            minlen = 3
            return true unless chat.response.content_type =~ /(text|script)/ 
            chat.request.get_parm_names.each do |parm|              
              pv = Regexp.quote(chat.request.get_parm_value(parm))
              parm_values.push pv unless pv.strip.empty? or pv.strip.length < minlen
            end
            chat.request.post_parm_names.each do |parm|
              pv = chat.request.post_parm_value(parm)
              parm_values.push pv unless pv.strip.empty? or pv.strip.length < minlen
            end
            
            parm_values.each do |parm_value|
              
              pattern = Regexp.quote(CGI.unescape(parm_value))
              if chat.response.body =~ /<script[^<\/]*#{pattern}/i then
               # puts "* Found: Parameter within script"
                addFinding(
                           :check_pattern => "#{parm_value}", 
                :proof_pattern => "#{parm_value}",
                :chat=>chat,
                :title =>"[#{parm_value}] - #{chat.request.path}"
                )
                
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
