# .
# cert_store.rb
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
  module CertStore
    @fake_certs = Hash.new
    def self.acquire_ssl_ctx(target, cn)
      ctx = OpenSSL::SSL::SSLContext.new()

      unless @fake_certs.has_key? target
        cert_prefs = {
          :hostname => cn,
          :type => 'server',
          :user => 'watobo',
          :email => 'watobo@localhost',
        }
        cert_file, key_file = Watobo::CA.create_cert cert_prefs
        fake_cert = OpenSSL::X509::Certificate.new(File.read(cert_file))
        fake_key = OpenSSL::PKey::RSA.new(File.read(key_file))

        #ctx = OpenSSL::SSL::SSLContext.new('SSLv23_server')
        @fake_certs[target] = { :cert => fake_cert, :key => fake_key }

      end
      fc = @fake_certs[target]
      ctx.cert = fc[:cert]
      ctx.key = fc[:key]

      ctx.tmp_dh_callback = proc { |*args|
        Watobo::CA.dh_key
      }

      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx.timeout = 10
      return ctx
    end
  end
end