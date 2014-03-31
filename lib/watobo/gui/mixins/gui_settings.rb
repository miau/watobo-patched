# .
# gui_settings.rb
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
  module Gui
    module Settings
       def self.save_gui_settings(settings)
        wd = Watobo.working_directory

        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "gui")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_settings.yml")
        
        Watobo::Utils.save_settings(file, config)
      end

      def load_gui_settings()
        wd = Watobo.working_directory
        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "gui")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_settings.yml")
        config = Watobo::Utils.load_settings(file)
        config
      end
    end
  end
end