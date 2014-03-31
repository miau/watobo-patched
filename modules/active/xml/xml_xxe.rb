# .
# xml_xxe.rb
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
      module Xml
        class Xml_xxe < Watobo::ActiveCheck
          # This module checks if DTD is accepted
          # The idea is to use regular parameters and convert them to entity
          # if the result is the same, chances are good that XXE attacks will work
          
          @info.update(
            :check_name => 'XML-XXE',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => "XML",
            :description => "XML eXternal Entity (XXE).",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            threat = "https://www.owasp.org/index.php/Testing_for_XML_Injection_(OWASP-DV-008)"
            
            measure = "Disable external entities."
            
            @finding.update(
            :threat => threat,        # thread of vulnerability, e.g. loss of information
            :class => "External Entities",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
          end
          
          def generateChecks(chat)
            begin              
              if ( chat.request.content_type =~ /xml/ ) and chat.request.has_body?
                # first we do a request with an
                base = chat.copyRequest
                base_request, base_response = doRequest(base)
                return unless base_response.has_body?
                create_entity_packets(chat.request.body).each do |packet|
                  checker = proc {
                    begin                      
                      test_request = nil
                    test_response = nil
                    test = chat.copyRequest
                    test.setData packet.to_s
                    test_request, test_response = doRequest(test)
                    #puts test_response.status
                    
                    if test_response.has_body? and test_response.body == base_response.body
                     
                      addFinding(test_request,test_response,
                      :test_item => "ENTITY",
                      :check_pattern => "ENTITY",
                      :chat => chat,
                      :title => "[#{chat.request.path}] - ENTITY",
                      :debug => true
                      )
                    end
                    rescue => bang
                      puts bang
                      puts bang.backtrace if $DEBUG                      
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  
                   end
              end
            rescue => bang
              puts bang
            end
          end
          
          private
          
          def create_entity_packets(xml_string)
  xml_packets = []

  xmlbase = Nokogiri::XML(xml_string)
  xmlbase.traverse do |node|
    if node.text?
      unless node.text.strip.empty?
        xml = Nokogiri::XML(xml_string)
        xml.create_internal_subset("#{node.parent.name}", nil, nil)
        node_name = ""
        node_name << "#{node.parent.namespace.prefix}:" unless node.parent.namespace.prefix.nil?
        node_name << "#{node.parent.name}"
        add_entity(xml, "#{node_name}", "#{node.parent.name}", "#{node.text}")
        xml_packets << xml

      end
    end
  end
  xml_packets
end

def add_entity(xml, node_name, entity_name, value)
  xml.create_entity(entity_name, Nokogiri::XML::EntityDecl::INTERNAL_GENERAL, nil, nil, value)
  entity = Nokogiri::XML::EntityReference.new xml, entity_name
  nodeset = xml.xpath("//#{node_name}")  
  nodeset.first.send(:native_content=, entity.to_s ) unless nodeset.empty?  
end

        end
        # --> eo namespace    
      end
    end
  end
end