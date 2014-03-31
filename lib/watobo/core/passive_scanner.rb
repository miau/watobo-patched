# .
# passive_scanner.rb
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
  module PassiveScanner
    @queue = Queue.new
    @max_threads = 1
    @scanners = []
    class Engine
      def initialize
        @t = nil
      end

      def run
        @t = Thread.new{
          loop do
            chat = Watobo::PassiveScanner.pop
            unless chat.nil?
              Watobo::PassiveModules.each do |test_module|
                begin
                  test_module.do_test(chat)
                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                  return false
                end
              end
            end
         end
        }
      end
    end

    def self.pop
      return @queue.pop
    end

    def self.start
      @max_threads.times do |i|
        e = Engine.new
        e.run
      end
    end

    def self.add(chat)
      @queue.push chat
    end

  end
end