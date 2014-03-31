# .
# ca.rb
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
  module CA
    @cadir = File.join(Watobo.working_directory, "CA")
    @crl_dir= File.join(@cadir, "crl")
    @hostname = %x('hostname').strip
    @hostname = "watobo" if @hostname.empty?
    @domain = "#{@hostname}.watobo.local"
    def self.ca_ready?
      return false unless File.exists? @ca_config[:CA_dir]
      return false unless File.exists? @ca_config[:private_dir]
      return false unless File.exists?  @ca_config[:fake_certs_dir]
      return false unless File.exists?  @ca_config[:crl_dir]
      return false unless File.exists?  @ca_config[:csr_dir]
      return true
    end

    # return 0
    @ca_config = {
      :CA_dir => @cadir,
      # need a password here .... mmmhhhhh ...,
      :password => "watobo",

      :keypair_file => File.join(@cadir, "private/cakeypair.pem"),
      :cert_file => File.join(@cadir, "cacert.pem"),
      :serial_file => File.join(@cadir, "serial"),
      :fake_certs_dir => File.join(@cadir, "fake_certs"),
      :new_keypair_dir => File.join(@cadir, "private/keypair_backup"),
      :csr_dir => File.join(@cadir, "csr"),
      :crl_dir => File.join(@cadir, 'crl'),
      :private_dir => File.join(@cadir, 'private'), #, 0700

      :ca_cert_days => 5 * 365, # five years
      :ca_rsa_key_length => 2048,

      :cert_days => 365, # one year
      :cert_key_length_min => 1024,
      :cert_key_length_max => 2048,

      :crl_file => File.join(@crl_dir, "#{@hostname}.crl"),
      :crl_pem_file => File.join(@crl_dir, "#{@hostname}.pem"),
      :crl_days => 14,
      :name => [
        ['C', 'DE', OpenSSL::ASN1::PRINTABLESTRING],
        ['O', @domain, OpenSSL::ASN1::UTF8STRING],
        ['OU', @hostname, OpenSSL::ASN1::UTF8STRING],
      ]
    }

    unless Watobo::CA.ca_ready? then
      Dir.mkdir(@ca_config[:CA_dir])
      Dir.mkdir @ca_config[:private_dir]
      Dir.mkdir @ca_config[:fake_certs_dir]
      Dir.mkdir @ca_config[:crl_dir]
      Dir.mkdir @ca_config[:csr_dir]

      File.open @ca_config[:serial_file], 'w' do |f| f << '1' end

      #print "Generating CA keypair ..."
      #puts " - rsa_key_length: " + @ca_config[:ca_rsa_key_length].to_s
      keypair = OpenSSL::PKey::RSA.new(@ca_config[:ca_rsa_key_length])
      #puts "done!"

      #print "Create Certificate ..."
      cert = OpenSSL::X509::Certificate.new
      #puts "done!"
      name = @ca_config[:name].dup << ['CN', 'CA']

      cert.subject = cert.issuer = OpenSSL::X509::Name.new(name)
      cert.not_before = Time.now
      cert.not_after = Time.now + @ca_config[:ca_cert_days] * 24 * 60 * 60
      cert.public_key = keypair.public_key
      cert.serial = 0x0
      cert.version = 2 # X509v3
     # puts "Init ExtensionFactory ..."
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension("basicConstraints","CA:TRUE", true),
        #  ef.create_extension("nsComment","Ruby/OpenSSL Generated Certificate"),
        ef.create_extension("nsComment","WATOBO CA"),
        ef.create_extension("subjectKeyIdentifier", "hash"),
        ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
      ]
      cert.add_extension ef.create_extension("authorityKeyIdentifier",
      "keyid:always,issuer:always")
     # puts "Sign Certificate ..."
      cert.sign keypair, OpenSSL::Digest::SHA1.new

      cb = proc do @ca_config[:password] end
      keypair_export = keypair.export OpenSSL::Cipher::DES.new(:EDE3, :CBC),
      &cb

      #puts "Writing keypair to #{@ca_config[:keypair_file]}"
      begin
        fh = File.open(@ca_config[:keypair_file], "w+")

        fh.puts keypair_export
        fh.close
      rescue => bang
        puts "! Could not write keypair"
        puts bang
      end

      #puts "Writing cert to #{@ca_config[:cert_file]}"
      File.open @ca_config[:cert_file], "w", 0644 do |f|
        f << cert.to_pem
      end

      puts "Done generating certificate for #{cert.subject}"
    else
      #puts "Open Cert File ..."
      raw = File.read @ca_config[:cert_file] # DER- or PEM-encoded
      cert = OpenSSL::X509::Certificate.new raw
     # puts cert

    end

    def self.create_cert(cert_config)
    #  puts " ... keypair ..."
      cert_keypair = create_key(cert_config)
    #  puts "... csr ..."
      cert_csr = create_csr(cert_config, cert_keypair)
   #   puts "... signing ..."
      signed_cert = sign_cert(cert_config, cert_keypair, cert_csr)
      return signed_cert, cert_keypair
    end

    ##
    # Creates a new RSA key from +cert_config+.

    def self.create_key(cert_config)
      #passwd_cb = nil
      target = cert_config[:hostname] || cert_config[:user]
     # puts target
      dest = @ca_config[:fake_certs_dir]
     # puts dest
      keypair_file = File.join(dest, (target + "_keypair.pem"))
      keypair_file.gsub!(/\*/,"_")
      
      return keypair_file if File.exist? keypair_file

      #puts "create_key: #{keypair_file}"
      begin
        Dir.mkdir dest #, 0700
      rescue Errno::EEXIST
       # puts "directory exists"
      end

      if not File.exists?(keypair_file) then
        #puts "Generating RSA keypair" if $DEBUG
        keypair = OpenSSL::PKey::RSA.new 1024
       # puts keypair.to_pem.class

        if cert_config[:password].nil? then
        #  puts "no password for cert"
        #  puts "Writing keypair to #{keypair_file}" if $DEBUG
          begin
            dummy = keypair.to_pem.split("\n")
            dummy.each do |line|
              line.strip!
            end
            fh = File.open( keypair_file, "wb" )
            fh.write dummy.join("\n")
            fh.close
          rescue => bang
            puts "! Could not write keypair"
            puts bang
            puts bang.backtrace
          end
        else
        # passwd_cb = proc do cert_config[:password] end
          keypair_export = keypair.export OpenSSL::Cipher::DES.new(:EDE3, :CBC), cert_config[:password]

         # puts "Writing keypair to #{keypair_file}" if $DEBUG
          #File.open keypair_file, "w" do |f|
          #  f << keypair_export
          #end
          begin
            fh = File.open( keypair_file, "w" )
            fh.puts keypair_export
            fh.close
          rescue => bang
            
            puts "! Could not write keypair"
            puts bang
            puts bang.backtrace
          end

        end
      end
      return keypair_file
    end

    ##
    # Signs the certificate described in +cert_config+ and
    # +csr_file+, saving it to +cert_file+.

    def self.sign_cert(cert_config, cert_file, csr_file)
      
      target = cert_config[:hostname] || cert_config[:user]
      dest = @ca_config[:fake_certs_dir]
      cert_file = File.join dest, "#{target}_cert.pem"
      cert_file.gsub!(/\*/,"_")
      return cert_file if File.exist? cert_file
      
      csr = OpenSSL::X509::Request.new File.read(csr_file)

      raise "CSR sign verification failed." unless csr.verify csr.public_key

      if csr.public_key.n.num_bits < @ca_config[:cert_key_length_min] then
        raise "Key length too short"
      end

      if csr.public_key.n.num_bits > @ca_config[:cert_key_length_max] then
        raise "Key length too long"
      end

      if csr.subject.to_a[0, @ca_config[:name].size] != @ca_config[:name] then
        raise "DN does not match"
      end

      # Only checks signature here.  You must verify CSR according to your
      # CP/CPS.

      # CA setup

      puts "Reading CA cert from #{@ca_config[:cert_file]}" if $DEBUG
      ca = OpenSSL::X509::Certificate.new File.read(@ca_config[:cert_file])

      puts "Reading CA keypair from #{@ca_config[:keypair_file]}" if $DEBUG
      ca_keypair = OpenSSL::PKey::RSA.new File.read(@ca_config[:keypair_file]),
      @ca_config[:password]

      serial = File.read(@ca_config[:serial_file]).chomp.hex
      File.open @ca_config[:serial_file], "w" do |f|
        f << "%04X" % (serial + 1)
      end

      puts "Generating cert" if $DEBUG

      cert = OpenSSL::X509::Certificate.new
      from = Time.now
      cert.subject = csr.subject
      cert.issuer = ca.subject
      cert.not_before = from
      cert.not_after = from + @ca_config[:cert_days] * 24 * 60 * 60
      cert.public_key = csr.public_key
      cert.serial = serial
      cert.version = 2 # X509v3

      basic_constraint = nil
      key_usage = []
      ext_key_usage = []

      case cert_config[:type]
      when "ca" then
        basic_constraint = "CA:TRUE"
        key_usage << "cRLSign" << "keyCertSign"
      when "terminalsubca" then
        basic_constraint = "CA:TRUE,pathlen:0"
        key_usage << "cRLSign" << "keyCertSign"
      when "server" then
        basic_constraint = "CA:FALSE"
        key_usage << "digitalSignature" << "keyEncipherment"
        ext_key_usage << "serverAuth"
      when "ocsp" then
        basic_constraint = "CA:FALSE"
        key_usage << "nonRepudiation" << "digitalSignature"
        ext_key_usage << "serverAuth" << "OCSPSigning"
      when "client" then
        basic_constraint = "CA:FALSE"
        key_usage << "nonRepudiation" << "digitalSignature" << "keyEncipherment"
        ext_key_usage << "clientAuth" << "emailProtection"
      else
      raise "unknonw cert type \"#{cert_config[:type]}\""
      end

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = ca
      ex = []
      ex << ef.create_extension("basicConstraints", basic_constraint, true)
      ex << ef.create_extension("nsComment",
      "Ruby/OpenSSL Generated Certificate")
      ex << ef.create_extension("subjectKeyIdentifier", "hash")
      #ex << ef.create_extension("nsCertType", "client,email")
      unless key_usage.empty? then
        ex << ef.create_extension("keyUsage", key_usage.join(","))
      end
      #ex << ef.create_extension("authorityKeyIdentifier",
      #                          "keyid:always,issuer:always")
      #ex << ef.create_extension("authorityKeyIdentifier", "keyid:always")
      unless ext_key_usage.empty? then
        ex << ef.create_extension("extendedKeyUsage", ext_key_usage.join(","))
      end

      if @ca_config[:cdp_location] then
        ex << ef.create_extension("crlDistributionPoints",
        @ca_config[:cdp_location])
      end

      if @ca_config[:ocsp_location] then
        ex << ef.create_extension("authorityInfoAccess",
        "OCSP;" << @ca_config[:ocsp_location])
      end
      cert.extensions = ex
      cert.sign ca_keypair, OpenSSL::Digest::SHA1.new

      #  backup_cert_file = @ca_config[:backup_certs_dir] + "/cert_#{cert.serial}.pem"
      #  puts "Writing backup cert to #{backup_cert_file}" if $DEBUG
      #  File.open backup_cert_file, "w", 0644 do |f|
      #    f << cert.to_pem
      #  end

      # Write cert
      puts "Writing cert to #{cert_file}"
      File.open cert_file, "w", 0644 do |f|
        f << cert.to_pem
      end

      return cert_file
    end

    ##
    # Creates a new Certificate Signing Request for the keypair in
    # +keypair_file+, generating and saving new keypair if nil.

    def self.create_csr(cert_config, keypair_file = nil)
      keypair = nil
      target = cert_config[:hostname] || cert_config[:user]
      dest = @ca_config[:csr_dir]
      csr_file = File.join dest, "csr_#{target}.pem"
      csr_file.gsub!(/\*/,"_")
      
      return csr_file if File.exist? csr_file

      name = @ca_config[:name].dup
      case cert_config[:type]
      when 'server' then
        name << ['OU', 'CA']
        name << ['CN', cert_config[:hostname]]
      when 'client' then
        name << ['CN', cert_config[:user]]
        name << ['emailAddress', cert_config[:email]]
      end
     #puts "Create Certificate Signing Request ..."
     # puts "Keypair File: " + keypair_file
      #  puts name
      name = OpenSSL::X509::Name.new(name)
     # puts "- - -"

      if File.exists? keypair_file then
      #  puts "Get Keypair from file #{keypair_file}"
        keypair = OpenSSL::PKey::RSA.new(File.read(keypair_file), cert_config[:password])
      else
      # puts "Create Certificate KeyPair ..."
        keypair = create_key(cert_config)
      end

    #  puts "Generating CSR for #{name}" if $DEBUG

      req = OpenSSL::X509::Request.new
      req.version = 0
      req.subject = name
      req.public_key = keypair.public_key
      req.sign keypair, OpenSSL::Digest::MD5.new

    #  puts "Writing CSR to #{csr_file}" if $DEBUG
      File.open csr_file, "w" do |f|
        f << req.to_pem
      end

      return csr_file
    end

    def self.dh_key
      dh_filename = File.join(@ca_config[:CA_dir], "watobo_dh.key")
      unless File.exist? dh_filename
        #puts "* no dh key file found"
        File.open(dh_filename,"w") do |fh|
          puts "* creating SSL key (DH 1024) ... "
          fh.write OpenSSL::PKey::DH.new(1024).to_pem
          print " DONE\r\n"
        end
      end
      OpenSSL::PKey::DH.new(File.read(dh_filename))
    end
  end
end