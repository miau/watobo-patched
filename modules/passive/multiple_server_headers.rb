# .
# multiple_server_headers.rb
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
      
      class Multiple_server_headers < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Collect Server Headers',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Identify Server Header Information, e.g. Apache 6.x ",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Information about the system maybe revealed',        # thread of vulnerability, e.g. loss of information
          :class => "Server Headers",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
          @server_list = []
        end
        
        def do_test(chat)
          begin
            
            chat.response.headers.each do |header|
              if header =~ /^server: (.*)/i then
                server_banner = $1.strip 
                #server_banner.gsub!(/^[ ]+/,"")
                
                unless @server_list.include?(chat.request.site + server_banner)
                  #puts "found different server header"
                  @server_list.push chat.request.site + server_banner
                  # puts "[#{chat.id}]: #{server_banner}"
                  addFinding(
                             :proof_pattern => "Server: #{server_banner}", 
                  :chat => chat,
                  :title => server_banner
                  )
                end
                
              end
              
              if header =~ /X-Powered-By: (.*)/i then
                match = $1.strip               
                unless @server_list.include?(chat.request.site + match)
                  #puts "found different server header"
                  @server_list.push chat.request.site + match
                  # puts "[#{chat.id}]: #{server_banner}"
                  addFinding(
                             :proof_pattern => "#{match}", 
                  :chat => chat,
                  :title => "#{match}"
                  )
                end
                
              end
              
            end
            
          end
        rescue => bang
          puts "ERROR!! #{Module.nesting[0].name}"
          puts bang
          puts bang.backtrace if $DEBUG
          puts chat.request.url
        end
      end
      
      
    end
  end
end
