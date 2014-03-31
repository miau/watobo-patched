# .
# xss_rated.rb
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
    module Active
      module Xss
        
        
        class Xss_rated < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            threat =<<'EOF'
Cross-site Scripting (XSS) is an attack technique that involves echoing attacker-supplied code into a user's browser instance. 
A browser instance can be a standard web browser client, or a browser object embedded in a software product such as the browser 
within WinAmp, an RSS reader, or an email client. The code itself is usually written in HTML/JavaScript, but may also extend to 
VBScript, ActiveX, Java, Flash, or any other browser-supported technology.

When an attacker gets a user's browser to execute his/her code, the code will run within the security context (or zone) of the 
hosting web site. With this level of privilege, the code has the ability to read, modify and transmit any sensitive data accessible 
by the browser. A Cross-site Scripted user could have his/her account hijacked (cookie theft), their browser redirected to another 
location, or possibly shown fraudulent content delivered by the web site they are visiting. Cross-site Scripting attacks essentially 
compromise the trust relationship between a user and the web site. Applications utilizing browser object instances which load content 
from the file system may execute code under the local machine zone allowing for system compromise.

Source: http://projects.webappsec.org/Cross-Site+Scripting
EOF
            
            measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"
            
            @info.update(
                         :check_name => 'Rated Cross Site Scripting Checks',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_XSS,
            :description => "Checking every URL parameter for missing output sanitisation. The results have a rated exploitability.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "Reflected XSS [RATED]",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_HIGH,
            :measure => measure
            )
            
            @envelop = [ "watobo", "watobo".reverse]
            @evasions = [ "%0a", "%00"]
            @xss_chars= %w( < > ' " ) 
            @escape_chars = ['\\']       
            
          end
          
          
          def generateChecks(chat)    
            #
            #  Check GET-Parameters
            #
            begin
              
              log_console("generating checks ...")
              urlParmNames(chat).each do |parm|
                log_console( parm )
                # puts "#{Module.nesting[0].name}: run check on chat-id (#{chat.id}) with parm (#{parm})"
                pval = chat.request.get_parm_value(parm)
                checks = []
                @xss_chars.each do |xss|
                   tp = "#{@envelop[0]}"
                   tp << CGI.escape(xss)
                   tp << "#{@envelop[1]}"
                   pattern = "#{@envelop[0]}([^#{@envelop[0]}]*#{xss})#{@envelop[1]}"   
                   checks << [ xss.dup, "#{tp}" , pattern ]
                   checks << [xss.dup, "#{pval}#{tp}", pattern ]
                   checks << [xss.dup, "#{tp}#{pval}", pattern ]
                      
                  end
                  checker = proc {
                    results = {}
                    rating = 0
                       test_request = nil
                      test_response = nil
               
                    
                    checks.each do |xss, check, proof|
                      next if results.has_key? xss
                      test = chat.copyRequest
                      test.replace_get_parm(parm, check)
                        
                      test_request,test_response = doRequest(test)
                                       
                      if not test_response then
                        if $DEBUG
                        puts "[#{Module.nesting[0].name}] got no response :("
                        puts test
                        end
                      elsif test_response.join =~ /#{proof}/i
                        match = $1
                      #  puts "MATCH: #{match}/#{xss}"
                        if match == xss
                        results[xss] = { :match => :full, :check => check, :proof => proof }
                        end
                        
                        unless results.has_key? xss
                          @escape_chars.each do |ec|
                            ep = Regexp.quote("#{ec}#{xss}")
                          #  puts "Escaped: #{match} / #{ep}"
                            results[xss] = { :match => :escaped, :check => check, :proof => proof} if match =~ /#{ep}/
                          end
                        end
                        
                        results[xss] = { :match => :modified, :check => check, :proof => proof } unless results.has_key? xss
                        
                      end
                      puts results.to_yaml if $DEBUG
                    end
                    
                   
                    xss_combo = ""
                   results.each do |k,v|
                     mp = CGI.escape(k)
                     rp = CGI.escape(@xss_chars.join)
                     case v[:match]
                     when :full
                         rating += 100/@xss_chars.length
                         xss_combo = v[:check].gsub(/#{mp}/, rp)
                       when :escaped
                          rating += 100/(@xss_chars.length*4)
                          xss_combo = v[:check].gsub(/#{mp}/, rp) if xss_combo.empty?
                       when :modified
                         rating += 100/(@xss_chars.length*4)
                         xss_combo = v[:check].gsub(/#{mp}/, rp) if xss_combo.empty?
                       end
                   end                   
                    
                    if rating > 0
                      test = chat.copyRequest
                      puts "COMBO-REQUEST: #{xss_combo}"
                      test.replace_get_parm(parm, xss_combo)
                        
                    #  puts "Reflected XSS: #{ts}"
                   #     pattern = "#{@envelop[0]}[^#{@envelop[0]}]*(\\\\)?#{@xss_chars.join('(\\\\)?')}#{@envelop[1]}"
                      match = ""
                      pattern = "#{@envelop[0]}([^#{@envelop[0]}]*(#{@xss_chars.join("|")})+[^#{@envelop[0]}]*)#{@envelop[1]}"
                      test_request,test_response = doRequest(test)
                      if not test_response then
                        puts "got no response :("
                      elsif test_response.join =~ /#{pattern}/i
                        match = $1
                        puts "MATCH: #{match}"
                      end
                     
                      addFinding( test_request, test_response,
                                 :check_pattern => xss_combo, 
                      :proof_pattern => "#{match}", 
                      :test_item => parm,
                      :class => "Reflected XSS", 
                      :chat => chat,
                      :title => "[#{parm} - #{rating}%] - #{test_request.path}"
                      )
                    end
                    #@project.new_finding(:short_name=>"#{parm}", :check=>"#{check}", :proof=>"#{pattern}", :kategory=>"XSS-Post", :type=>"Vuln", :chat=>test_chat, :rating=>"High")
                    [ test_request, test_response ]
                  }
                  yield checker
               
              end
             
              
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
              
              
            end
          end
          
        end
        
      end
    end
  end
end
