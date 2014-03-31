# .
# finding.rb
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
  class Finding < Conversation

    @@numFindings = 0
    @@max_id = 0

    @@lock = Mutex.new

    attr :details
    attr :request
    attr :response
    def resetCounters()
      @@numFindings = 0
      @@max_id = 0
    end

    def id()
      @details[:id]
    end

    def false_positive?
      @details[:false_positive]
    end

    def set_false_positive
      @details[:false_positive] = true
    end

    def unset_false_positive
      @details[:false_positive] = false
    end
    
    def method_missing(name, *args, &block)
      if @details.has_key? name
        return @details[name]
      end
      super
    end

    def initialize(request, response, details = {})
      super(request, response)
      @details = {
        :id => -1,
        :comment => '',
        :false_positive => false    # FalsePositive
      }

      @details.update details if details.is_a? Hash

      @@lock.synchronize{
      # enter critical section here ???
        if @details[:id] > 0 and @details[:id] > @@max_id
          @@max_id = @details[:id]
        elsif @details[:id] < 0
          @@max_id += 1
          @details[:id] = @@max_id
        end
        @@numFindings += 1

      }
    #  extendRequest()
    #  extendResponse()

    end

  end
end