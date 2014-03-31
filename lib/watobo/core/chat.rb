# .
# chat.rb
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
  class Chat < Conversation
    attr :request
    attr :response
    attr :settings

    @@numChats = 0
    @@max_id = 0

    @@lock = Mutex.new

    public
    def resetCounters()
      @@numChats = 0
      @@max_id = 0
    end

    def tested?()
      return false unless @settings.has_key?(:tested)
      return @settings[:tested]
    end

    def tested=(truefalse)
      @settings[:tested] = truefalse
    end

    def tstart()
      @settings[:tstart]
    end

    def tstop()
      @settings[:tstop]
    end

    def id()
      @settings[:id]
    end

    def comment=(c)
      @settings[:comment] = c
    end

    def comment()
      @settings[:comment]
    end
    
    def use_ssl?
      request.proto =~ /https/
    end

    def source()
      @settings[:source]
    end


    # INITIALIZE ( request, response, prefs )
    # prefs:
    #   :source - source of request/response CHAT_SOURCE
    #   :id     - an initial id, if no id is given it will be set to the @@max_id, if id == 0 counters will be ignored.
    #   :start  - starting time of request format is Time.now.to_f
    #   :stop   - time of loading response has finished
    #   :
    def initialize(request, response, prefs = {})

      begin
        super(request, response)

        @settings = {
          :source => CHAT_SOURCE_UNDEF,
          :id => -1,
          :start => 0,
          :stop => -1,
          :comment => '',
          :tested => false
        }

        @settings.update prefs
        #  puts @settings[:id].to_s

        @@lock.synchronize{
        # enter critical section here ???
          if @settings[:id] > @@max_id
            @@max_id = @settings[:id]
          elsif @settings[:id] < 0
            @@max_id += 1
            @settings[:id] = @@max_id
          end
          @@numChats += 1
        # @comment = ''
        # leafe critical section here ???
        }

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

  end
end