# .
# detect_fileupload.rb
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
  module Modules
    module Passive
      class Detect_fileupload < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)

          @info.update(
          :check_name => 'Detect File Upload Functionality',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects file upload functions which may be exploited to upload malicious file contents.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'File upload functions sometimes can be exploited to upload malicious code. This can lead to server- or client-side code excecution.',        # thread of vulnerability, e.g. loss of information
          :class => "File Uploads",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @pattern_list = []
          @pattern_list << Regexp.new("<input [^>]*type=.file.")

        end

        def do_test(chat)
          begin
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/
                          
              @pattern_list.each do |pat|
              #puts "+check pattern #{pat}"
                if pat.match(chat.response.body) # =~ /(#{pat})/i then
                #   puts "!!! MATCH (FILE UPLOAD)!!!"
                match = $1
                #   puts match
                addFinding(
                :check_pattern => "#{pat}",
                :proof_pattern => "#{match}",
                :title => "#{chat.request.path_ext}",
                :chat => chat
                )

                end
              end
            else
            # puts chat.response.content_type
            end
          rescue => bang
          puts "ERROR!! #{Module.nesting[0].name}"
          puts bang
          end
        end
      end

    end
  end
end
