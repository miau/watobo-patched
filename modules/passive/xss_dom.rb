# .
# xss_dom.rb
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
      
      
      class Xss_dom < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'DOM XSS',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks for suspcious javascript functions which manipulate the Browsers DOM and may be misused for Cross-Site-Scripting-Attacks.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Parameter value may be exploitable for XSS.',        # thread of vulnerability, e.g. loss of information
          :class => "DOM XSS",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
            @dom_functions = [ 'document\.write',
                               'document\.url',
                               'document\.location',
                               #'document\.execCommand',
                               'document\.attachEvent',
                               'eval\(',
                               'window\.open',
                               'window\.location',
                               #'document\.create',
                               "\.innerHTML",
                               "\.outerHTML"]
        end
        
        def showError(chatid, message)
          puts "!!! Error"  
          puts "Chat: [#{chatid}]"
          puts message
        end
        
        def do_test(chat)
          begin

            return true unless chat.response.content_type =~ /(text|script)/ 
            
            @dom_functions.each do |pattern|
              if chat.response.body =~ /(#{pattern})/i then
               match = $1.strip
               match.gsub!(/^[\.\(\)]+/,'')
               match.gsub!(/[\.\(\)]+$/,'')
                addFinding(
                           :check_pattern => "#{pattern}", 
                :proof_pattern => "#{pattern}",
                :chat=>chat,
                # :title =>"[#{pattern}] - #{chat.request.path}",
                :title =>"[ #{match} ]"
                #:class => "DOM XSS"            
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
