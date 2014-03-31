# .
# crawler.rb
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
begin
  require 'mechanize'
rescue LoadError
  puts "To use the crawler plugin you must install the 'mechanize' gem."
  puts "Simply enter the command 'gem install mechanize'"
end




path = File.expand_path(File.dirname(__FILE__))

%w( constants bags grabber engine uri_mp).each do |l|
  require File.join(path, "lib", l)
end
 
if $0 == __FILE__
  # @private 
module Watobo#:nodoc: all
    module Conf
      class Interceptor
        def self.port
 #         8081
        nil
        end
      end
    end
  end
  
  require 'yaml'
  if ARGV.length > 0
    url = ARGV[0]
  end
 
  hook = lambda{ |agent, request|
    begin
      puts request.class
      puts request.method
      puts request.methods.sort
     
      exit
      clean_jar = Mechanize::CookieJar.new
      agent.cookie_jar.each{|cookie|
        puts "Cookie: #{cookie.name}"
        clean_jar.add! cookie unless cookie.name =~ /^box/i
      }
      exit unless agent.cookie_jar.empty?(request.url.to_s)
      agent.cookie_jar = clean_jar
    rescue => bang
      puts bang
      puts bang.backtrace
    end

  }
  hook = nil
 
  crawler = Watobo::Crawler::Engine.new
  crawler.run(url, :pre_connect_hook => hook, :num_grabbers => 1 )
end
