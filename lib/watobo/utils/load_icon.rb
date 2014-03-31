# .
# load_icon.rb
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
  module Utils
    def loadIcon(app, filename)
      begin
        icon = nil
        
        File.open(filename, "rb") do |f| 
          if filename.strip =~ /\.ico$/ then
            icon = FXICOIcon.new(app, f.read)
            #icon = FXICOIcon.new(getApp(), f.read)
          elsif filename.strip =~ /\.png$/ then
            icon = FXPNGIcon.new(app, f.read)
          elsif filename.strip =~ /\.gif$/ then
            icon = FXGIFIcon.new(app, f.read)
          end
          icon.create
        end
        
        icon
      rescue => bang
        puts "Couldn't load icon: #{filename}"
        puts bang
      end
    end
  end
end
