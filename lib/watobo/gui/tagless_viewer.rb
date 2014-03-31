# .
# tagless_viewer.rb
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
require 'watobo/gui/request_editor'
# @private 
module Watobo#:nodoc: all
  module Gui
    class TaglessViewer < SimpleTextView
      def normalizeText(text)
        return '' if text.nil?
        
        raw_text = text
        
        if text.is_a? Array then
        raw_text = text.join
        end

        #remove headers
        body_start = raw_text.index("\r\n\r\n")
        body_start = body_start.nil? ? 0 : body_start
        #puts "* start normalizing at pos #{body_start}"
        normalized = raw_text[body_start..-1]
        # UTF-8 Clean-Up
        normalized = normalized.unpack("C*").pack("C*")
        # remove all inbetween tags
        normalized.gsub!(/<.*?>/m, '')
        # remove non printable characters, except LF (\x0a)
        normalized.gsub!(/[\x00-\x09\x0b-\x1f\x7f-\xff]+/m,'')
        # remove empty lines
        normalized.gsub!(/((\x20+)?\x0a(\x20+)?)+/,"\n")
       # decode html entities for better readability
        normalized = CGI.unescapeHTML(normalized)
        # additionally unescape &nbsp; which is not handled by CGI :(
        normalized.gsub!(/(#{Regexp.quote('&nbsp;')})+/," ")
        # finally strip it
        normalized.strip
      end

      def initialize(owner, opts)
        super(owner, opts)
      end
    end

  end
end
