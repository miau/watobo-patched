# .
# forwarding_proxy.rb
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
  module ForwardingProxy
        
    def self.get(site=nil)
      begin
        return nil if Watobo::Conf::ForwardingProxy.default_proxy.empty?
        name = Watobo::Conf::ForwardingProxy.default_proxy
        fp = Watobo::Conf::ForwardingProxy.to_h
        proxy = fp[name]
        return Watobo::Proxy.new(proxy)
      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return nil
    end
  end
end