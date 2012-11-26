# .
# save_scanner_settings.rb
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
    def self.save_scanner_settings()
      unless Watobo.project.nil?

        Watobo::Conf::Scanner.save_project(Watobo.project.session_store ){ |s|
        # puts s.to_yaml
          x
        }

        session_filter = [ :sid_patterns, :logout_signatures, :custom_error_patterns, :max_parallel_checks, :excluded_parms, :non_unique_parms ]
        Watobo::Conf::Scanner.save_session(Watobo.project.session_store)
      return true
      else
        Watobo::Conf::Scanner.save
      end
    end
  end
end