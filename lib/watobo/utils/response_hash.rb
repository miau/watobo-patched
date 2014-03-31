# .
# response_hash.rb
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
require 'digest/md5'

module Watobo
  module Utils
    def Utils.responseHash(request, response)
      begin
        if request.body and response.body then
          #     request.extend Watobo::Mixin::Parser::Web10
          #     request.extend Watobo::Mixin::Shaper::Web10

          #     response.extend Watobo::Mixin::Parser::Web10
          #     response.extend Watobo::Mixin::Shaper::Web10

          body = response.body

          # remove all parm/value pairs
          request.get_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            val = request.get_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
          end
          request.post_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            val = request.post_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
          end
        # remove date format 01.02.2009
        body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
        # remove date format 02/2009
        body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
        #remove time
        body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')

        return body, Digest::MD5.hexdigest(body)

        elsif response.body then
        return body, Digest::MD5.hexdigest(response.body)
        else
        return nil
        end
      rescue => bang
      puts bang
      puts bang.backtrace if $DEBUG
      end
      return nil

    end

    # smart hashes are necessary for blind sql injections tests
    # SmartHash means that all dynamic information is removed from the response before creating the hash value.
    # Dynamic information could be date&time as well as parameter names and theire valuse.
    def Utils.smartHash(orig_request, request, response)
      begin
        if request and response.body then

          body = response.body.dup
          # remove possible chunk values
          body.gsub!(/\r\n[0-9a-fA-F]+\r\n/,'')
          # remove date format 01.02.2009
          body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
          # remove date format 02/2009
          body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
          #remove time
          body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')
          # remove all non-printables
          body.gsub!(/[^[:print:]]/,'')

          request.get_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(p))}/, '')

            val = request.get_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(val))}/, '')

          end

          request.post_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(p))}/, '')

            val = request.post_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(val))}/, '')
          end

          # remove all parm/value pairs
          orig_request.get_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(p))}/, '')

            val = orig_request.get_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(val))}/, '')
          end

          orig_request.post_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(p))}/, '')

            val = orig_request.post_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
            body.gsub!(/#{Regexp.quote(CGI::unescape(val))}/, '')
          end
        return body, Digest::MD5.hexdigest(body)
        else
        puts "!!! SMART-HASH is NIL !!!!"
        # puts request
        # puts "----------------------"
        # puts response.body
        return nil
        end
      rescue => bang
      puts bang
      puts bang.backtrace if $DEBUG
      return body, Digest::MD5.hexdigest(body||="")
      end

    end

  end
end
