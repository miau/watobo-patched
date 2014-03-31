# .
# save_proxy_settings.rb
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
  def self.save_proxy_settings(prefs={})

    c_prefs = {
      :save_passwords => false,
      :key => ""
    }

    c_prefs.update prefs

    unless Watobo.project.nil?
      Watobo::Conf::ForwardingProxy.save_project() do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    else

      Watobo::Conf::ForwardingProxy.save do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    end

  end

end