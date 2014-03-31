# .
# detect_infrastructure.rb
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
      class Detect_infrastructure < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)

          @info.update(
          :check_name => 'Infrastructure Information',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Searching for information in response body which may reveal information about Plattform, CMS-Systems, Application Server, ...",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'Information about the underlying infrastructure may help an attacker to perform specialized attacks.',        # thread of vulnerability, e.g. loss of information
          :class => "Infrastructure",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @pattern_list = []
          @pattern_list << [ 'Server', Regexp.new('<address>(.*)Server at') ]
          @pattern_list << [ 'eZPublish CMS', Regexp.new('title="(eZ Publish)')]
          @pattern_list << [ 'Imperia CMS', Regexp.new('content=[^>]*(IMPERIA [\d\.]*)')]
          @pattern_list << [ 'Typo3 CMS', Regexp.new('content=[^>]*(TYPO3 [\d\.]* CMS)')]
          @pattern_list << [ 'Open Text CMS', Regexp.new('published by[^>]*(Open Text Web Solutions[\-\s\d\.]*)')]
          #<meta name="generator" content="Sefrengo / www.sefrengo.org" >
          #<meta name="author" content="CMS Sefrengo">
          @pattern_list << [ 'Sefrengo CMS', Regexp.new('content=[^>]*(Sefrengo[\s\d\.]*)')]
          @pattern_list << [ 'Tomcat', Regexp.new('(Apache Tomcat\/\d{1,4}\.\d{1,4}\.\d{1,4})') ]
          @pattern_list << [ 'Microsoft-IIS', Regexp.new('<img src="welcome.png" alt="(IIS7)"')]
#          When it’s a SharePoint 2010 site, you will get the result is like this: MicrosoftSharePointTeamServices: 14.0.0.6106
@pattern_list << [ 'SharePoint 2010', Regexp.new('MicrosoftSharePointTeamServices.*14.0.0.6106')]
# And in SharePoint 2007 site, the result is like this: MicrosoftSharePointTeamServices:12.0.0.4518
@pattern_list << [ 'SharePoint 2007', Regexp.new('MicrosoftSharePointTeamServices.*12.0.0.4518')]
          

          #@pattern_list << 'sample code'

        end

        def do_test(chat)
          begin
             # puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/ then
              
                @pattern_list.each do |pat|

                  if chat.response.join =~ /(#{pat[1]})/i then
                    #   puts "!!! MATCH !!!"
                    match = $1
                    addFinding(
                    :proof_pattern => "#{match}",
                    :chat => chat,
                    :title => "[#{pat[0]}] - #{match.slice(0..15)}"
                    )
                    break
                  end
              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            if $DEBUG
              puts bang.backtrace 
              puts chat.response.join
            end
          end
        end
      end

    end
  end
end
