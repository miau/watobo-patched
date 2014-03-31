# .
# create_project.rb
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
  @project_name = ''
  @session_name = ''
  @project = nil
  
  def self.project_name
    @project_name
  end 
  
  def self.session_name
    @session_name
  end
 
  def self.project
    @project
  end

  # create_project is a wrapper function to create a new project
  # you can either create a project by giving a URL (:url),
  # or by giving a :project_name AND a :session_name
  def self.create_project(prefs={})
    project_settings = Hash.new
    # project_settings.update @settings

    if prefs.has_key? :url
      #TODO: create project_settings from url
      else
      project_settings[:project_name] = prefs[:project_name]
      project_settings[:session_name] = prefs[:session_name]
    end

    Watobo::DataStore.connect(project_settings[:project_name], project_settings[:session_name])
    @project_name = project_settings[:project_name]
    @session_name = project_settings[:session_name]

    # updating settings
    Watobo::Conf.load_project_settings()
    Watobo::Conf.load_session_settings()

    #project_settings[:session_store] = ds

    puts "* INIT PASSIVE MODULES"
    Watobo::PassiveModules.init
    puts
    puts "Total: " + Watobo::PassiveModules.length.to_s
   # project_settings[:passive_checks] = init_passive_modules
    #puts "Total: " + project_settings[:passive_checks].length.to_s
    #puts
    puts "* INIT ACTIVE MODULES"
    #project_settings[:active_checks] = init_active_modules
    Watobo::ActiveModules.init
    #  project_settings[:active_checks].each do |ac|
    #    puts ac.class
    #  end
    puts
    puts "Total: " + Watobo::ActiveModules.length.to_s
    puts

    project = Project.new(project_settings)
    #@running_projects << project
    @project = project

  end

end