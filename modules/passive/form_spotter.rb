# .
# form_spotter.rb
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
      
      
      class Form_spotter < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Form Spotter',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all HTML-Forms",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Lists all HTML-Forms.',        # thread of vulnerability, e.g. loss of information
          :class => "Forms",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "Check if all forms are checked for vulnerabilities." 
          )
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return true unless chat.response.content_type =~ /(text|script)/
            return true if chat.response.body.nil?
            off = chat.response.body.index(/<form/i, 0)
            until off.nil?
              action = chat.response.body[off..-1] =~ /<form [^<\/form]*action="([^"]*)"/i ? $1 : "undefined" 
              title = action.strip.empty? ? "[none]" : "#{action}"
            #  puts "!FOUND FORM #{action}"
              addFinding(  
                         :proof_pattern => "<form [^>]*>", 
              :title => title,
              :chat => chat
              )  
              off = chat.response.body.index(/<form/i, off+1)
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return false
        end
      end
      
    end
  end
end
