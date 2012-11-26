# .
# defaults.rb
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
  def self.load_defaults
    config_path = File.expand_path(File.join(File.dirname(__FILE__),"..","..", "config"))
    #   puts "* loading defaults from #{config_path}"
    Dir.glob("#{config_path}/*.yml").each do |cf|
      dummy = File.basename(cf).gsub!(/.yml/,'')
      #cc = dummy.strip.gsub(/[^[a-zA-Z\-_]]/,"").gsub( "-" , "_").split("_").map{ |s| s.downcase.capitalize }.join
      cc = Watobo::Utils.camelcase dummy
      begin
        settings = YAML.load_file(cf)
        Watobo::Conf.add(cc,  settings )
      rescue => bang
        puts "[#{self}] Could not load config #{cf}"
      end
    end
  end

end

#puts "=== loading defaults ==="
Watobo.load_defaults
