# .
# ajax.rb
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
require 'cgi'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Ajax < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Ajax',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Spots Ajax Frameworks like jQuery.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Framework may contain vulnerabilities.',        # thread of vulnerability, e.g. loss of information
          :class => "Ajax Framework",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
            @fw_patterns = []
            @fw_patterns << { :name => 'jQuery', :pattern => 'jQuery v([0-9\.]*) jquery.com'}
        end
        
        def showError(chatid, message)
          puts "!!! Error #{Module.nesting[0].name}"  
          puts "Chat: [#{chatid}]"
          puts message
        end
        
        def do_test(chat)
          begin
            return false if chat.response.nil?
            return false unless chat.response.has_body?
            return true unless chat.response.content_type =~ /(text|script)/ 
            
            @fw_patterns.each do |pattern|
              body = chat.response.body.unpack("C*").pack("C*")
              if body =~ /#{pattern[:pattern]}/i then
               version = $1.strip
               addFinding(
                           :check_pattern => "#{pattern[:pattern]}", 
                :proof_pattern => "#{pattern}",
                :chat=>chat,
                :title =>"[ #{pattern[:name]} #{version} ] - #{chat.request.path}",            
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
