# .
# conversation.rb
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
  class Conversation
    include Watobo::Constants
    attr_accessor :file
    def id()
      # must be defined
    end

    def copyRequest()
      # req_copy = []
      # self.request.each do |line|
      #   req_copy.push line.clone
      # end
      orig = Utils.copyObject(@request)
      # now extend the new request with the Watobo mixins
      #copy.extend Watobo::Mixin::Parser::Url
      #copy.extend Watobo::Mixin::Parser::Web10
      #copy.extend Watobo::Mixin::Shaper::Web10
       copy = Watobo::Request.new(orig)
      return copy
    end

    private

    # def extendRequest
    #   @request.extend Watobo::Mixin::Shaper::Web10
    #   @request.extend Watobo::Mixin::Parser::Web10
    #   @request.extend Watobo::Mixin::Parser::Url
    # end

    # def extendResponse
    #   @response.extend Watobo::Mixin::Parser::Web10
    # end

    def initialize(request, response)
      @request = Watobo::Request.new request
      @response = Watobo::Response.new response
      @file = nil

      #  extendRequest()
      #  extendResponse()
      #Watobo::Request.create @request
      #Watobo::Response.create @response

    end

  end

end