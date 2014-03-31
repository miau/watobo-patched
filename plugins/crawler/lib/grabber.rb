# .
# grabber.rb
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
  module Crawler
    class Grabber
      def get_page(linkbag)
        begin
          return nil if linkbag.nil?
          return nil unless linkbag.respond_to? :link
          page = nil

          uri = linkbag.link
          uri = linkbag.link.uri if linkbag.link.respond_to? :uri

          unless @opts[:head_request_pattern].empty?
            pext = uri.path.match(/\.[^\.]*$/)
            unless pext.nil?
              if pext[0] =~ /\.#{@opts[:head_request_pattern]}/i
              page = @agent.head uri
              end
            end
          end

          page = @agent.get uri if page.nil?

          sleep(@opts[:delay]/1000.0).round(3) if @opts[:delay] > 0
          return nil if page.nil?
          return PageBag.new( page, linkbag.depth+1 )
        rescue => bang
          puts bang #if $DEBUG
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def run
        Thread.new(@link_queue, @page_queue){ |lq, pq|
          loop do
            begin
              #link, referer, depth = lq.deq
              link = lq.deq
              next if link.depth > @opts[:max_depth]
              page = get_page(link)
              pq << page unless page.nil?

            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end
        }
      end

      def initialize(link_queue, page_queue, opts = {} )
        @link_queue = link_queue
        @page_queue = page_queue
        @opts = opts
        begin
          @agent = Crawler::Agent.new(@opts)
    
        rescue => bang
          puts bang
          puts bang.backtrace
        end

      end

    end
  end
end
