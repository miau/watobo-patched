# .
# sid_cache.rb
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
  class SIDCache
    @caches = {}
    @caches_lock = Mutex.new
    
    @pattern_lock = Mutex.new
    
    attr :sids
    
    
    def self.patterns
      Watobo::Conf::SidCache.patterns
    end
    
    def clear
      @sids = {}
    end
    
    def initialize()      
      @cache_lock = Mutex.new
      @sids = {}
    end
    
    def self.acquire(session)
      @caches_lock.synchronize do
        unless @caches.has_key? session
          @caches[session] = SIDCache.new()
        end
      end
      @caches[session]
    end
    
     def update_sids(site, response)
          begin
            #site = request.site
            @cache_lock.synchronize do
              response.each do |line|
                # puts line
                self.class.patterns.each do |pat|
                  if line =~ /#{pat}/i then
                    sid_key = Regexp.quote($1.upcase)
                    sid_value = $2
                    
                   # puts "#{self} GOT NEW SID (#{sid_key}): #{sid_value}"
                    @sids[site] ||= Hash.new 
                    @sids[site][sid_key] = sid_value
                  end
                end

              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG

          end
      end

    
    def update_request(request)
        @cache_lock.synchronize do
          if @sids.has_key?(request.site)
            valid_sids = @sids[request.site] 
            puts "* found sid for site: #{request.site}" if $DEBUG
            request.map!{ |line|
              res = line
              self.class.patterns.each do |pat|
                begin
                  if line =~ /#{pat}/i then
                    next if $~.length < 3
                    sid_key = Regexp.quote($1.upcase)
                    old_value = $2

                    if valid_sids.has_key?(sid_key) then
                      if not old_value =~ /#{@sids[request.site][sid_key]}/ then # sid value has changed and needs update
                        Watobo.print_debug("#{self} update session", "#{old_value} - #{@sids[request.site][sid_key]}") if $DEBUG
                        
                        unless old_value.empty?
                        res = line.gsub!(/#{Regexp.quote(old_value)}/, valid_sids[sid_key])
                        end
                        if not res then puts "!!!could not update sid (#{sid_key})"; end

                      end
                    end
                  end
                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                  # puts @cache.to_yaml
                end
              end
              res
            }
          end
        end
      end
    
  end
end