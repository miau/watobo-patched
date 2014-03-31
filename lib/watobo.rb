#!/usr/bin/ruby
# .
# watobo.rb
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
#Encoding: UTF-8
require 'rubygems'
require 'yaml'
require 'json'
require 'thread'
require 'socket'
require 'timeout'
require 'openssl'
require 'optparse'
require 'digest/md5'
require 'stringio'
require 'zlib'
require 'base64'
require 'cgi'
require 'uri'
require 'pathname'
require 'net/ntlm'
require 'drb'
require 'nokogiri'
require 'stringio'
require 'mechanize'

require 'watobo/constants'
require 'watobo/utils'
require 'watobo/mixins'
require 'watobo/config'
require 'watobo/defaults'
require 'watobo/core'
require 'watobo/externals'
require 'watobo/adapters'
require 'watobo/framework'
require 'watobo/http/data/data'
require 'watobo/http/url/url'
require 'watobo/http/cookies/cookies'
require 'watobo/parser'
require 'watobo/interceptor'
require 'watobo/http_socket'

# WORKAROUND FOR LINUX :(
dont_know_why_REQUIRE_hangs = Mechanize.new

# @private 
module Watobo#:nodoc: all #:nodoc: all

  VERSION = "0.9.15"

  def self.base_directory
    @base_directory ||= ""
    @base_directory = File.expand_path(File.join(File.dirname(__FILE__),".."))
  end

  def self.plugin_path
    @plugin_directory ||= ""
    @plugin_directory = File.join(base_directory, "plugins")
  end

  def self.active_module_path
    @active_module_path = ""
    @active_path = File.join(base_directory, "modules", "active")
  end
  
  def self.passive_module_path
    @passive_module_path = ""
    @passive_path = File.join(base_directory, "modules", "passive")
  end

  def self.version
    Watobo::VERSION
  end
  
  def self.print_summary
    puts "--- Info ---"
    puts "Version: " + version
    puts "Working Directory: " + Watobo.working_directory
    puts "Active Checks Location: " + Watobo.active_module_path
    puts "Passive Checks Location: " + Watobo.passive_module_path
    puts "---"
    puts
  end
end

Watobo.init_framework

require 'watobo/ca'
