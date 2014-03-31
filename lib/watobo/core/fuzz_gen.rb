# .
# fuzz_gen.rb
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
  
    # base class for generators
    class FuzzGenerator
      attr :numRequests
      attr :name
      attr :genType
      attr :actions
      attr :info
      
      def is_generator?
        true
      end

      def run(imr=nil)
        result = Hash.new

        result.update imr if imr

        generate do |value|
          rv = value
          @actions.each do |p|
            rv = p.func.call(rv)
          end
          result[@fuzzer_tag.name] = rv
          yield result

        end
      end

      def addAction(proc)
        @actions.push proc
      end

      def removeAction(action)
        @actions.delete(action)
      end

      def generate
        return true
      end

      def initialize(fuzzer_tag)
        @actions = []
        @numRequests = 0
        @fuzzer_tag = fuzzer_tag
        @genType = "Undefined"
        @info = "undefined"
      end

    end

    class FuzzFile < FuzzGenerator
      def generate
        return if not @filename
        fh = File.open(@filename)
        fh.each_line do |line|
          line.chomp!
          yield line if not line.empty?
        end
      end

      def initialize(fuzzer_tag, filename)
        super(fuzzer_tag)
        @genType = "File-Input"
        @filename = ""
        @numRequests = 0
        if File.exists?(filename) then
          @filename = filename
          File.open(filename) do |fh|
            fh.each_line do |l|
              @numRequests += 1
            end
          end
        else
          @numRequests = 0
        end

        @info = "Filename: #{@filename}"

      end

    end

    class FuzzList < FuzzGenerator
      def generate(&block)
        @list.each do |item|
          yield item if block_given?
        end
      end

      def initialize(fuzzer_tag, list)
        @list = list
        super(fuzzer_tag)
        @genType = "List-Input"
        @numRequests = @list.length
        @info = "#{@numRequests} values"
      end
    end

    class FuzzCounter < FuzzGenerator
      attr_reader :start, :stop, :count, :step
      
      def generate
        return false if @start.nil?
        return false if @stop.nil? and @count.nil?

        if @stop == 0 and @count > 0 then
          @stop = @start + @count
        end

        return 0 if @start == @stop

        @start.step(@stop, @step) do |i|
          yield i.to_s
        end

      end

      def initialize(fuzzer_tag, prefs)
        super(fuzzer_tag)
        @genType = "Counter"
        @start = prefs[:start]
        @stop =  prefs[:stop]

        @count = prefs[:count] || 0
        @step = ( prefs[:step] and prefs[:step] != 0 ) ? prefs[:step] : 1

        if @stop < @start and @step > 0 then
          @step = @step * -1
        end
        @info = "start=#{@start}/stop=#{@stop}/step=#{@step}"
        @numRequests = (( @stop - @start ) / @step).abs

      end

    end

end
