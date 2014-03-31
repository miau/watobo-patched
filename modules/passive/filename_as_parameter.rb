# .
# filename_as_parameter.rb
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
      
      
      class Filename_as_parameter  < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Detect Filename Parameters',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects parameters which sounds like 'filename', e.g. filename, fname.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'If filename parameters are not proper handled by the application an attacker may excecute malicious files or reveal sensitive information.',        # thread of vulnerability, e.g. loss of information
          :class => "Filename Parameter",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
        
          @possible_parm_names=%w[ (.*fname.*) (.*file.*) ]
          @findings = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            all_parms = chat.request.parm_names
            if all_parms
              # puts all_parms
              all_parms.each do |parm|
                @possible_parm_names.each do |pattern|
                  
                  if parm =~ /#{pattern}/i
                    match = $1
                    if not @findings.include?(parm)
                      @findings.push parm
                      addFinding(
                                 :check_pattern => match,
                                 :chat=>chat
                      )
                    end
                  end
                  
                  
                end
                
              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end
        end
        
      end
    end
  end
end
