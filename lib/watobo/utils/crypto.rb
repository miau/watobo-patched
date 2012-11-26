# .
# crypto.rb
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
require 'openssl'
require 'digest/sha1'
require 'base64'

# Thanks to : http://rails.brentsowers.com/2007/12/aes-encryption-and-decryption-in-ruby.html
module Watobo
module Crypto
  
  def Crypto.encryptPassword(plain_password, secret)
    Base64.encode64(Crypto.encrypt(plain_password, secret)).strip
  end
  
  def Crypto.decryptPassword(b64_encrypted_password, secret)
    ep = Base64.decode64(b64_encrypted_password)
    decrypt(ep, secret)
    end
    
    
  def Crypto.decrypt(encrypted_data, pass, iv=nil, cipher_type="AES-256-CBC")
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.decrypt
    aes.key = Digest::SHA256.digest(pass)
    aes.iv = iv if iv != nil
    aes.update(encrypted_data) + aes.final  
  end  
   
  def Crypto.encrypt(data, pass, iv=nil, cipher_type="AES-256-CBC")
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.encrypt
    aes.key = Digest::SHA256.digest(pass)
    aes.iv = iv if iv != nil
    aes.update(data) + aes.final      
  end
end
end

if __FILE__ == $0
  # TODO Generated stub
 # cipher = "AES-256-CBC"
  pass = "password"
  #iv = nil
  
  plaintext = "S3cr3t"
  1000.times do |i|
  plaintext += (rand(65)+35).chr + "OK"
  encrypted = Crypto.encrypt(plaintext, pass)
  puts encrypted
  
  puts "* now decrypt again"
  plain = Crypto.decrypt(Base64.decode64(encrypted), pass)
  puts plain
  end
end