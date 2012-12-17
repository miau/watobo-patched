# .
# hotspots.rb
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
    module Passive
      
      
      class Hotspots < Watobo::PassiveCheck
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Active Content References',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all references to active content pages, e.g. php, asp.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'References to active content pages have been found. Sometimes old and/or vulnerable functions are revealed. With this information you can also estimate if all parts of the application are covered.',        # thread of vulnerability, e.g. loss of information
          :class => "Hotspots",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "Check if these references are only pointing to \"good\" functions." 
          )
         
          
        
          @pattern_list = %w( php asp aspx jsp cgi )
		  
          @known_functions = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            if chat.response.content_type =~ /(text|script)/ and chat.response.status !~ /404/ then
              if Utils.decode(chat.response).each do |chunk|
                  chunk.split(/\n/).each do |line|
                    @pattern_list.each do |ext|
                      if line =~ /([\w%\/\\\.:-]*\.#{ext})[^\w]/ then
                        match = $1
                        if not @known_functions.include?(match) then
                          addFinding(  
                                       :proof_pattern => match, 
                                       :title => match,
                                       :chat => chat
                          )  
                          @known_functions.push match
                        end
                      end                  
                    end
                  end
                end
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end
        end
      end
      
    end
  end
end
