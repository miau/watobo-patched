# .
# in_script_parameter.rb
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
          puts "!!! Error #{Module.nesting[0].name}"  
          puts "Chat: [#{chatid}]"
          puts message
        end
        
        def do_test(chat)
          begin
            minlen = 3
            return true unless chat.response.content_type =~ /(text|script)/
            return true unless chat.response.has_body?
            
            parm_list = chat.request.parameters(:data, :url)
            return true if parm_list.empty?
            body = chat.response.body.unpack("C*").pack("C*")
            
            doc = Nokogiri::HTML(body)
            scripts = doc.css('script')
            
            parm_list.each do |parm|
              next if parm.value.nil?
              next if parm.value.empty?
              next if parm.value.length <= minlen
                            
              pattern = Regexp.quote(CGI.unescape(parm.value))
              scripts.each do |script|
              if script.text =~ /#{pattern}/i then
               # puts "* Found: Parameter within script"
                addFinding(
                           :check_pattern => "#{parm.value}", 
                           :proof_pattern => "#{parm.value}",
                           :chat=>chat,
                           :title =>"[#{parm.value}] - #{chat.request.path}"
                )
              end
                
              end
            end
          rescue => bang
            # raise
            showError(chat.id, bang)
            #puts bang.backtrace
            
          end
        end
        
      end
    end
  end
end
