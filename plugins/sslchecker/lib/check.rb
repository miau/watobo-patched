# .
# check.rb
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
  module Plugin
    module Sslchecker
      class Check < Watobo::ActiveCheck
        attr :cipherlist
        
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
          
          
        def initialize(project)
          super(project)

          @result = Hash.new
          @cipherlist = Array.new
          
          
          OpenSSL::SSL::SSLContext::METHODS.each do |method|
            next if method =~ /(client|server)/
            next if method =~ /23/
          #%w( TLSv1_server SSLv2_server SSLv3_server ).each do |method|
            puts ">> #{method}"
            begin
          ctx = OpenSSL::SSL::SSLContext.new(method)
          ctx.ciphers="ALL::COMPLEMENTOFALL::eNull"
          ctx.ciphers.each do |c|
            @cipherlist.push [ method, c[0]]
          end
          #ctx.ciphers="eNULL" # because ALL don't include Null-Ciphers!!!
          #ctx.ciphers.each do |c|
          #  @cipherlist.push [ method, c[0]]
          #end

          
          rescue => bang
            puts bang
          end
          
          end
         # puts @cipherlist.to_yaml
        end

        def reset()
          @result.clear
        end

        def generateChecks(chat)
          begin
            @cipherlist.each do |method, c|
            checker = proc {

              test_request = nil
              test_response = nil
              # !!! ATTENTION !!!
              # MAKE COPY BEFORE MODIFIYING REQUEST
              request = chat.copyRequest

              
                ctx = OpenSSL::SSL::SSLContext.new(method)
                ctx.ciphers = c
                cypher = ctx.ciphers.first
                bits = cypher[2].to_i
                algo = cypher[0]
              
                test_request, test_response = doRequest( request, :ssl_cipher => c )
                result = {
                    :method => method, 
                    :algo => algo, 
                    :bits => bits, 
                    :support => true
                  }
              
                if test_request and test_response
                  
              
                  notify( :cipher_checked, result)
                  if bits < 128

                  addFinding(  test_request, test_response,
                  :test_item => "#{algo}#{bits}",
                  #:proof_pattern => "#{match}",
                  :chat => chat,
                  :title => "[#{algo}] - #{bits} Bit"
                  )
                  end
                else
                  result[:support] = false
                notify(:cipher_checked, result)
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


