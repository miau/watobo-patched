# .
# core.rb
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
=begin
    lib_folder = "core"
    path = File.expand_path(File.join(File.dirname(__FILE__), lib_folder))
    puts "* loading #{lib_folder}"
    Dir.glob("#{path}/*.rb").each do |cf|
      puts "+ #{cf}" if $DEBUG
      require cf

    end
=end
%w( project scanner proxy session fuzz_gen http_socket interceptor passive_check active_check cookie request response intercept_filter intercept_carver forwarding_proxy cert_store netfilter_queue ).each do |lib|
  require File.join( "watobo", "core", lib)
end
