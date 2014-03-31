# .
# config.rb
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
  module Conf

    @@settings = Hash.new
    @count = 0
    @@modules = []
    
    def self.each(&b)
      @@modules.each do |m|
        yield m if block_given?
      end
      @@modules.length
    end
    
    def self.load_project_settings()
      @@modules.each do |m|
        m.load_project()
      end
    end
    
    def self.load_session_settings()
      @@modules.each do |m|
        m.load_session()
      end
    end

    def self.add(group, settings)
      #   puts "* create new configuration for #{group}"

      module_eval("module #{group}; @settings = #{settings}; end")
      m = const_get(group)
      m.module_eval do
        def self.to_file
       #   n = self.to_s.gsub(/(Watobo)?::/, "/").gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr("-","_").downcase
          n = Watobo::Utils.snakecase self.to_s.gsub(/(Watobo)?::/, "/")
          n << ".yml"
        end

        def self.update(filename=nil, &b)
          n = self.to_file
          file = filename unless filename.nil?
          file = File.join( Watobo::Conf::General.working_directory, n )
          if File.exist? file
            puts " [#{self}] update settings from file #{file}" if $DEBUG
            @settings.update YAML.load_file(file)
          else
            puts "! [#{self}] could not update settings from file #{file}" if $DEBUG
          end
        end
        
        # returns the group name of the module
        # e.g. the group name of Watobo::Conf::Interceptor would be Interceptor
        def self.group_name
          self.to_s.gsub(/.*::/,"")
        end

        def self.set(settings)
          return false unless settings.is_a? Hash
          @settings = YAML.load(YAML.dump(settings))
        end

        def self.save_session( *filter, &b)
          #raise ArgumentError, "Need a valid Watobo::DataStore" unless data_store.respond_to? :save_project_settings
          s = filter_settings filter
          s = yield s if block_given?
         # puts group_name
          Watobo::DataStore.save_session_settings( group_name, s )
        end

        def self.save_project( *filter, &b)
         # raise ArgumentError, "Need a valid Watobo::DataStore" unless data_store.respond_to? :save_project_settings
          s = filter_settings filter
          s = yield s if block_given?
         # puts @settings.to_yaml
         # puts s.to_yaml
          Watobo::DataStore.save_project_settings(group_name, s)
        end
        
        def self.load_session(prefs={}, &b)
          
          p = { :update => true }
          p.update prefs
          
          s = Watobo::DataStore.load_session_settings(group_name)
          return false if s.nil?
          
          if p[:update] == true
            @settings.update s
          else
            @settings = s
          end
        end
        
        def self.load_project(prefs={}, &b)
          p = { :update => true }
          p.update prefs
          
          s = Watobo::DataStore.load_project_settings(group_name)
          return false if s.nil?
          
          if p[:update] == true
            @settings.update s
          else
            @settings = s
          end
        end

        def self.filter_settings(f)
          s = YAML.load(YAML.dump(@settings))
          
          return s unless f.is_a? Array
          return s if f.empty?
          #return s unless s.respond_to? :each_key
          
          s.each_key do |k|
              s.delete k unless f.include? k
          end
          s
        end

        def self.save(path=nil, *filter, &b)

          n = self.to_file
          p = Conf::General.working_directory
          unless path.nil?
            if File.exist? path
            p = path
            end
          end

          file = File.join( p, n )

          s = filter_settings filter
          

          yield s if block_given?

          if File.exist?(File.dirname(file))
            puts "* save config #{self} to: #{file}"
            puts s.to_yaml
           
            File.open(file, "w") { |fh|
              YAML.dump(s, fh)
            }
          else
            puts "Could not save file to #{File.dirname(file)}"
          end
        end

        def self.respond_to?(f)
          #  puts "* respond_to?"
          # puts f
          return true if @settings.has_key? f.to_sym
          #  puts @settings.to_yaml
          super
        end

        def self.dump
          @settings
        end
        
        def self.to_h
          @settings
        end
        

        #@@settings = settings
        def self.method_missing(name, *args, &block)
          #  puts "* instance method missing (#{name})"
          if name =~ /(.*)=$/
          @settings.has_key? $1.to_sym || super
          @settings[$1.to_sym] = args[0]
          else
          # puts @settings[name.to_sym]
          @settings[name.to_sym]

          end
        end

        # TODO: create a class-instance of the module itself, so it can be referenced like @scanner.scope
        # before creating the reference also check if there's another class-instance variable with the same name
        def self.included_UNUSED(clazz)
          puts "* #{self} gets included into #{clazz}"
          @settings.each_key do |k|
            puts "* add method for #{k}"

            clazz.class_eval "
            @@#{k} ||= #{self}.#{k}

            def #{k}=(value)
            @@#{k} = value
            end

            def #{k}
            @@#{k}
            end
            "

          end
        end

      end
      @@modules << m
    end

  end
end