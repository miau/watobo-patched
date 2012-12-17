# .
# disclosure_ipaddr.rb
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
      
      class Disclosure_ipaddr < Watobo::PassiveCheck
               
        def initialize(project)
          @project = project
          super(project)
          @info.update(
            :check_name => 'IP Adress Disclosure',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => 'Looks for (internal) IP adresses.',   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
          )
          
          @finding.update(
            :threat => 'Internal information may be revealed, which could help an attacker to prepare further attacks',        # thread of vulnerability, e.g. loss of information
            :class => "IP Adress Disclosure",# vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :measure => "Remove all information which reveal internal information." 
            )
          
          @pattern = '[^\d\.](\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[^(\d\.)]+?'
          @known_ips = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            if chat.response.content_type =~ /text/ then
              if Utils.decode(chat.response).each do |line|
                  if line =~ /#{@pattern}/ then
                    ip_addr = $1
                    octets = ip_addr.split('.')
                    isIP = true
                    octets.each do |o|
                      isIP = false if o.to_i > 255 
                    end
                    if isIP then
                    title = "IP: #{ip_addr}"
                    dummy = chat.request.site + ":" + ip_addr
                    if not @known_ips.include?(dummy)
                      addFinding( :proof_pattern => ip_addr, 
                                  :chat => chat,
                                  :title => title)  
                      @known_ips.push dummy
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
