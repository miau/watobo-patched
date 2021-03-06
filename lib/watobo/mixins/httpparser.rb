# .
# httpparser.rb
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
# http://www.ietf.org/rfc/rfc2396.txt
# http://en.wikipedia.org/wiki/URI_scheme

#
# http://www.mysite.com:80/my/path/show.php?p=aaa&debug=true
#
# proto = "http"
# host = "www.mysite.com"
# site = "www.mysite.com:80"
# dir = "my/path"
# file = "show.php"
# file_ext = "show.php?p=aaa&debug=true"
# path = "my/path/show.php"
# query = "p=aaa&debug=true"
# fext = "php"
# path_ext = "my/path/show.php?p=aaa&debug=true"

module Watobo
  module Mixin
  module Parser
    module Url
      include Watobo::Constants
      def file
        #@file ||= nil
        #return @file unless @file.nil?
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}[^\?]*\/(.*) HTTP.*/
          tmp = $1
          end_of_file_index = tmp.index(/\?/)

          if end_of_file_index.nil?
            @file = tmp
          elsif end_of_file_index == 0
            @file = ""
          else
            @file = tmp[0..end_of_file_index-1]
          end

        else
          @file = ""
        end
      end

      def file_ext
        #@file_ext ||= nil
        #return @file_ext unless @file_ext.nil?
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}[^\?]*\/(.*) HTTP.*/
          @file_ext = $1
        else
          @file_ext = ''
        end
      end

      # returns a string containing all urlparms
      # e.g. "parm1=first&parm2=second"
      def urlparms
        begin
          off = self.first.index('?')
          return nil if off.nil?
          eop = self.first.index(' HTTP/')
          return nil if eop.nil?
          parms = self.first[off+1..eop-1]
          return parms
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def method
        if self.first =~ /(^[^[:space:]]{1,}) http/i then
          return $1
        else
          return nil
        end
      end

      #The path may consist of a sequence of path segments separated by a
      #single slash "/" character.  Within a path segment, the characters
      #"/", ";", "=", and "?" are reserved.  Each path segment may include a
      #sequence of parameters, indicated by the semicolon ";" character.
      #The parameters are not significant to the parsing of relative
      #references.

      #
      # http://www.mysite.com:80/my/path/show.php?p=aaa&debug=true
      # path = "my/path/show.php"
      def path
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/([^\?]*).* HTTP/i then
          return $1
        else
          return ""
        end
      end

      # path_ext = "my/path/show.php?p=aaa&debug=true"
      def path_ext
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/(.*) HTTP\//i then
          return $1
        else
          return ""
        end
      end

      def dir
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/([^\?]*)\/.* HTTP/i then
          return $1
        else
          return ""
        end
      end

      def query
        begin
          q = nil
          if self.first =~ /^[^[:space:]]{1,} (.*) HTTP.*/ then
            uri = $1
          end
          off = uri.index('?')
          #parts.shift
          # puts "HTTPParser.query: #{parts.join('?')}"
          return "" if off.nil?
          return uri[off+1..-1]
        rescue => bang
          puts "!!! Could not parse query !!!"
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return ''

      end

      def element
        cl = self.first.gsub(/\?+/,"?")
        cl.gsub!(/ HTTP.*/, '')
        dummy = cl.split('?').first
        if dummy =~ /^[^[:space:]]{1,} (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}).*\/(.*)/i then
          return $2
        else
          return ""
        end
      end

      def doctype
        /.*\/.*?\.(\w{2,4})(\?| )/.match(self.first)
        #   puts $1
        return $1 unless $1.nil?
        return ''
        #dummy = self.first.gsub(/\?+/,"?")
        #parts = dummy.split('?')
        #parts[0].gsub!(/ HTTP\/(.*)/i,"")
        #if parts[0] =~ /(.*\.)(\w{2,3})$/i then
        #  return $2
        #else
        #  return ''
        #end
      end

      def proto
       # @proto ||= nil
       # return @proto unless @proto.nil?
        @proto = "http" if self.first =~ /^[^[:space:]]{1,} http:\/\//i
        #  puts dummy
        @proto = "https" if self.first =~ /^[^[:space:]]{1,} https:\/\//i
        @proto
      end

      def is_ssl?
        return true if self.first =~ /^[^[:space:]]{1,} https/i
        return false
      end

      def is_chunked?
        self.each do |h|
          return true if h =~ /^Transfer-Encoding.*chunked/i
          break if h.strip.empty?
        end
        return false
      end

      def url
        #@url ||= nil
        #return @url unless @url.nil?
        if self.first =~ /^[^[:space:]]{1,} (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}.*) HTTP\//i then
          @url = $1
        else
          @url = ''
        end
        @url
      end

      def site
        #@site ||= nil
        #return @site unless @site.nil?
        if self.first =~ /^[^[:space:]]{1,} (https?):\/\/([\-0-9a-zA-Z.]*)([:0-9]{0,6})/i then
          host = $2
          port_extension = $3
          proto = $1
          s = host + port_extension
          if port_extension == ''
            s = host + ":" + DEFAULT_PORT_HTTPS.to_s if  proto =~ /^https$/i
            s = host + ":" + DEFAULT_PORT_HTTP.to_s if  proto =~ /^http$/i
          end
          @site = s
        else
          @site = nil
        end
        @site
      end

      def host
        #@host ||= nil
        #return @host unless @host.nil?
        if self.first =~ /^[^[:space:]]{1,} https?:\/\/([\-0-9a-zA-Z.]*)[:0-9]{0,6}/i then
          @host = $1
        else
          @host = ''
        end
        @host
      end

      # returns all subdir combinations
      # www.company.com/this/is/my/path.php
      # returns:
      # [ "/this", "/this/is", "/this/is/my" ]
      def subDirs
        sub_dirs = self.dir.split(/\//)
        dir = ""
        sub_dirs.map! do |d| dir += "/" + d ; end
        return sub_dirs
      end

      def port
        return nil if self.first.nil?
        dummy = self.first
        portnum = nil
        parts = dummy.split('?')

        if parts[0] =~ /^[^[:space:]]{1,} https:\/\//i then
          portnum = 443
        elsif parts[0] =~ /^[^[:space:]]{1,} http:\/\//i
          portnum = 80
        end
        if parts[0] =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*:([0-9]{0,6})/i then
          portnum = $1
        end
        return portnum
      end

      # get_parms returns an array of parm=value
      def get_parms
        begin
          off = self.first.index('?')
          return [] if off.nil?
          eop = self.first.index(' HTTP/')
          return [] if eop.nil?
          parms = self.first[off+1..eop-1].split('&').select {|x| x =~ /=/ }
          #   puts parms
          return parms
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return []
        #parmlist=[]
        #if self.first =~ /^[^[:space:]]{1,} (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}).*\/.*(\?.*=.*) HTTP/i then
        #  dummy = $2.gsub!(/\?+/,"?").split('?')
        # remove left part of ? from url
        #  dummy.shift

        #  parmlist=dummy.join.split(/\&/)
        #end
        #return parmlist

      end

      #################### doubles

      def get_parm_names

        parm_names=[]
        parmlist=[]
        parmlist.concat(get_parms)

        parmlist.each do |p|
          if p then
            p.gsub!(/=.*/,'')
            parm_names.push p
          end
        end

        return parm_names

      end

      def get_parm_value(parm_name)
        parm_value = ""
        self.get_parms.each do |parm|
          if parm =~ /^#{Regexp.quote(parm_name)}=/i then
            dummy = parm.split(/=/)
            if dummy.length > 1 then
              #  parm_value=dummy[1].gsub(/^[ ]*/,"")
              parm_value=dummy[1].strip
            end
          end
        end
        return parm_value
      end

      def post_parm_value(parm_name)
        parm_value=""
        self.post_parms.each do |parm|
          if parm =~ /#{Regexp.quote(parm_name)}/i then
            dummy = parm.split(/=/)
            if dummy.length > 1 then
              parm_value = dummy[1].strip
            else
              # puts "Uhhhh ... need parameter value from '#{parm}''"
            end
          end
        end
        return parm_value
      end

    end

    module Web10
      include Watobo::Constants
      def post_parms
        parmlist=[]
        return parmlist unless has_body?
        begin
        if self.last =~ /\=.*\&?/i
          parmlist = self.last.split(/\&/)
        end
        rescue => bang
          puts bang
           puts self.last.unpack("C*").pack("C*").gsub(/[^[:print:]]/,".")
          if $DEBUG
          puts bang.backtrace 
         
          end
        end
        return parmlist
      end

      def parms
        parmlist=[]
        parmlist.concat(get_parms)
        parmlist.concat(post_parms)

        return parmlist
      end

      def parm_names
        parm_names=[]
        parmlist=[]
        parmlist.concat(get_parms)
        parmlist.concat(post_parms)
        parmlist.each do |p|
          p.gsub!(/=.*/,'')
          parm_names.push p
        end

        return parm_names

      end

      def post_parm_names

        parm_names=[]
        parmlist=[]

        parmlist.concat(post_parms)
        parmlist.each do |p|
          if p then
            p.gsub!(/=.*/,'')
            parm_names.push p
          end
        end

        return parm_names

      end

      #     def get_parm_names

      #       parm_names=[]
      #       parmlist=[]
      #       parmlist.concat(get_parms)

      #       parmlist.each do |p|
      #        if p then
      #           p.gsub!(/=.*/,'')
      #           parm_names.push p
      #         end
      #       end

      #       return parm_names

      #     end

      def header_value(header_name)
        header_values =[]
        self.headers.each do |header|
          begin
          if header =~ /^#{header_name}/i then
            dummy = header.split(/:/)
            value=dummy[1]
            value.gsub!(/^[ ]*/,"")
            header_values.push value
          end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
        return header_values
      end

      def content_type
        ct = "undefined"
        self.each do |line|
          break if line.strip.empty?
          if line =~ /^Content-Type: (.*)/i then
            ct = $1
            break
          end
        end
        return ct.strip
      end

      def content_length
        # Note: Calculate Chunk-Encoded Content-Length
        # this is only possible if the whole body is loaded???
        ct = -1
        self.each do |line|
          break if line.strip.empty?
          if line =~ /^Content-Length: (.*)/i then
            ct = $1.to_i
            break
          end
        end
        return ct
      end

def content_encoding
        te = TE_NONE
        self.each do |line|
          break if line.strip.empty?
          if line =~ /^Content-Encoding: (.*)/i then
            dummy = $1.strip
            puts "Content-Encoding => #{dummy}"
            te = case dummy
            when /chunked/i
              TE_CHUNKED
            when /compress/i
              TE_COMPRESS
            when /zip/i
              TE_GZIP
            when /deflate/i
              TE_DEFLATE
            when /identity/i
              TE_IDENTITY
            else
              TE_NONE
            end
            break
          end
        end
        return te
      end
      
      def transferEncoding
        te = TE_NONE
        self.each do |line|
          break if line.strip.empty?
          if line =~ /^Transfer-Encoding: (.*)/i then
            dummy = $1.strip
           # puts dummy
            te = case dummy
            when 'chunked'
              TE_CHUNKED
            when 'compress'
              TE_COMPRESS
            when 'zip'
              TE_GZIP
            when 'deflate'
              TE_DEFLATE
            when 'identity'
              TE_IDENTITY
            else
              TE_NONE
            end
            break
          end
        end
        return te
      end
      
      alias :transfer_encoding :transferEncoding

      def contentMD5
        b = self.body.nil? ? "" : self.body
        hash = Digest::MD5.hexdigest(b)
        return hash
      end

      #      def get_parm_value(parm_name)
      #        parm_value = ""
      #        self.get_parms.each do |parm|
      #          if parm =~ /^#{Regexp.quote(parm_name)}=/i then
      #            dummy = parm.split(/=/)
      #            if dummy.length > 1 then
      #              #  parm_value=dummy[1].gsub(/^[ ]*/,"")
      #              parm_value=dummy[1].strip
      #            end
      #          end
      #        end
      #        return parm_value
      #      end

      def post_parm_value(parm_name)
        parm_value=""
        self.post_parms.each do |parm|
          if parm =~ /#{Regexp.quote(parm_name)}/i then
            dummy = parm.split(/=/)
            if dummy.length > 1 then
              parm_value = dummy[1].strip
            else
              # puts "Uhhhh ... need parameter value from '#{parm}''"
            end
          end
        end
        return parm_value
      end

      def has_body?
        self.body.nil? ? false : true
      end

      def has_header?(name)
        self.each do |l|
          return false if l.strip.empty?
          return true if l =~ /^#{name}:/i
        end
        return false
      end

      def body
        begin
          #return nil if self.nil?
          return self.last if self[-2].strip.empty?
        rescue
          return nil
        end
      end

      def responseCode
        if self.first =~ /^HTTP\/... (\d+) /
          return $1
        else
          return nil
        end
      end

# returns array of new cookies 
# Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; Path=/
def new_cookies(&b)
  nc = []
  headers("Set-Cookie") do |h|
    cookie = Watobo::Cookie.new(h)
    yield cookie if block_given?
    nc.push cookie
  end
end

      def status
        begin
        # Filter bad utf-8 chars
        dummy = self.first.unpack("C*").pack("C*")

        if dummy =~ /^HTTP\/1\.\d{1,2} (.*)/i then
          return $1.chomp
        else
          return ''
        end
        rescue => bang
          if $DEBUG
          puts "! No Status Available !".upcase
          puts bang
          puts bang.backtrace
          end 
          return nil
        end
      end

      def headers(filter=nil, &b)
        begin
        header_list=[]
        self.each do |line|
          cl = line.unpack("C*").pack("C*")
          return header_list if cl.strip.empty?
          unless filter.nil?
            if cl =~ /#{filter}/
            yield line if block_given?
            header_list.push line
            end
          else
            yield line if block_given?
            header_list.push line
          end
        end
        return header_list
        rescue => bang
          puts "! no headers available !".upcase
          puts bang
          if $DEBUG
            puts bang.backtrace
            puts self.to_yaml
          end
          return nil
        end
      end

      def cookies
        cookie_list=[]
        self.headers.each do |line|
          if line =~ /Cookie2?: (.*)/i then
            clist = $1.split(";")
            clist.each do |c|
              # c.gsub!(/^[ ]+/,"")
              # c.chomp!
              cookie_list.push c.strip
            end
          end
        end
        return cookie_list
      end

      def data
        return self.last.strip if self.last =~ /\=.*\&?/i
        return ""
      end

    end

   
    end
  end
end