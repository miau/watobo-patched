# .
# cookie_xss.rb
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
      
      
      class Cookie_xss < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
            :check_name => 'Cookie XSS',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "If cookies will be used in the content body, they can be misused for XSS-Attacks.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'A cookie value has been found in the body of the HTML page. This may be exploited for XSS attacks.',        # thread of vulnerability, e.g. loss of information
            :class => "Cookie Security",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/
              all_cookies = chat.request.cookies
              if all_cookies
                # puts all_parms
                all_cookies.each do |cookie|
                  dummy = cookie.split("=")
                  cname = dummy.shift
                  cval = Regexp.quote(dummy.join)
                  
                    if chat.response.body =~ /#{cval}/ and cval.length > 5 then
                      
                      addFinding(:proof_pattern => "#{cval}", 
                      :check_pattern => "#{cval}", 
                      :chat => chat, 
                      :title => "[#{cname}] - #{chat.request.path}")
                      break
                    end

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
