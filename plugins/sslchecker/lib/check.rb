# .
# check.rb
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
  module Plugin
    module Sslchecker
      class Check < Watobo::ActiveCheck
        attr :cipherlist
        def initialize(project)
          super(project)

          @result = Hash.new

          @info.update(
          :check_name => 'SSL-Checker',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Test applikation for supportes SSL Ciphers.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'Attacks on weak encryption ciphers which may lead loss of privacy',        # thread of vulnerability, e.g. loss of information
          :class => "SSL Ciphers",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_LOW
          )

          ctx = OpenSSL::SSL::SSLContext.new()
          @cipherlist = Array.new
          ctx.ciphers="eNULL" # because ALL don't include Null-Ciphers!!!
          ctx.ciphers.each do |c|
            @cipherlist.push c[0]
          end

          ctx.ciphers="ALL"
          ctx.ciphers.each do |c|
            @cipherlist.push c[0]
          end
        end

        def reset()
          @result.clear
        end

        def generateChecks(chat)
          begin
            @cipherlist.each do |c|
            checker = proc {

              test_request = nil
              test_response = nil
              # !!! ATTENTION !!!
              # MAKE COPY BEFORE MODIFIYING REQUEST
              request = chat.copyRequest

              
                ctx = OpenSSL::SSL::SSLContext.new()
                ctx.ciphers = c
                cypher = ctx.ciphers.first
                bits = cypher[2].to_i
                algo = cypher[0]
              
                test_request, test_response = doRequest( request, :ssl_cipher => c )
              
                if test_request and test_response
              
                  notify( :cipher_checked, algo, bits, true)
                  if bits < 128

                  addFinding(  test_request, test_response,
                  :test_item => "#{algo}#{bits}",
                  #:proof_pattern => "#{match}",
                  :chat => chat,
                  :title => "[#{algo}] - #{bits} Bit"
                  )
                  end
                else
                notify(:cipher_checked, algo, bits, false)
                #              puts "!!! ERROR: #{c}"
                end
              
              [ test_request, test_response ]

            }
            yield checker
            end
          rescue => bang
          puts "!error in module #{Module.nesting[0].name}"
          puts bang
          end
        end
      end

      
    end
  end
end


