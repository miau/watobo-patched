# .
# client_cert_store.rb
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
 @private 
module Watobo#:nodoc: all
  module ClientCertStore#:nodoc: all
    @client_certs = {}
    
#    :ssl_client_cert
#    :ssl_client_key
#    :extra_chain_certs
    
    def self.clear
      @client_certs.clear
    end
    
    def self.set( site, cert )
      return false if cert.nil?
      @client_certs[ site.to_sym ] = cert
      true
    end
    
    def self.get( site )
      return nil unless @client_certs.has_key? site.to_sym
      @client_certs[ site.to_sym ]
    end
    
end
end