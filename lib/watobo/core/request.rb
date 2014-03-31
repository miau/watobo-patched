# .
# request.rb
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
  def self.create_request(url, prefs={})
    u = "http://" unless url =~ /^http/
    u << url
    uri = URI.parse u
     r = "GET #{uri.to_s} HTTP/1.0\r\n"
     r << "Host: #{uri.host}" 
     r.extend Watobo::Mixins::RequestParser
     r.to_request
  end
  
  module Request
    def self.create request
      request.extend Watobo::Mixin::Parser::Url
      request.extend Watobo::Mixin::Parser::Web10
      request.extend Watobo::Mixin::Shaper::Web10
    end
  end
end