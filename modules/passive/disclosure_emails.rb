# .
# disclosure_emails.rb
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
      
      
      class Disclosure_emails < Watobo::PassiveCheck
        
        def initialize(project)
           @project = project
          super(project)
          
          @info.update(
            :check_name => 'Email Adresses',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Collects email adresses.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'email adresses can be used for social engineering attacks.',        # thread of vulnerability, e.g. loss of information
            :class => "EMail Adresses",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
          valid = '[a-zA-Z\d\.+-]+'
          @pattern = "#{valid}@#{valid}\\.(#{valid}){2}"
          @mail_list = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            if chat.response.content_type =~ /text/ and not chat.response.content_type =~ /text.csv/ then
            if chat.response.each do |line|
                if line =~ /(#{@pattern})/ then
                  match = $1
                  if not @mail_list.include?(match) then
                    @mail_list.push match
                    addFinding( 
                                         :proof_pattern => "#{match}", 
                                         :chat => chat,
                                         :title => match
                                         )
                                         end
                end
                
              end
            end
            end
          rescue => bang
          #  raise
            puts "ERROR!! #{self.class}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end
      
    end
  end
end
