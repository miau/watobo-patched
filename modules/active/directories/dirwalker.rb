# .
# dirwalker.rb
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
  module Modules
    module Active
      module Directories
        
        #class Dir_indexing < Watobo::Mixin::Session
        class Dirwalker < Watobo::ActiveCheck
          @@tested_directories = Hash.new
          
           @info.update(
                         :check_name => 'Directory Walker',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Do request on each directory and run passive checks on result.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
           
            
            
          end
          
          def reset()
            @@tested_directories.clear
          end
          
          def generateChecks(chat)
            
            begin
              path = chat.request.dir
              if !@@tested_directories.has_key?(path) then
                @@tested_directories[path] = true
                checker = proc {
                  begin
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      test.strip_path()
                      test_request, test_response = doRequest(test, :default => true)
                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                  end
                  [ test_request, test_response ]
                  
                }
                yield checker
              end
            rescue => bang
              puts "!error in module #{Module.nesting[0].name}"
              puts bang
            end
          end
          
        end
      end
    end  
  end
end
