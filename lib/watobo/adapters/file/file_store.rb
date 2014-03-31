# .
# file_store.rb
# 
# Copyright 2012 by siberas, http://www.siberas.de
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
module Watobo
  class FileSessionStore < SessionStore
    def num_chats
      get_file_list(@conversation_path, "*-chat").length
    end

    def num_findings
      get_file_list(@findings_path, "*-finding").length
    end

    def add_finding(finding)
      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding")
      if not File.exists?(finding_file) then

        finding_data = {
          :request => finding.request.map{|x| x.inspect},
          :response => finding.response.map{|x| x.inspect},
          :details => Hash.new
        }
        finding_data[:details].update(finding.details)

        if not File.exists?(finding_file) then
          fh = File.new(finding_file, "w+b")
          fh.print YAML.dump(finding_data)
        fh.close
        end
      end

    end
    
    def delete_finding(finding)
      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding")
      File.delete finding_file if File.exist? finding_file
      
    end
    
    def update_finding(finding)
      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding")
       finding_data = {
          :request => finding.request.map{|x| x.inspect},
          :response => finding.response.map{|x| x.inspect},
          :details => Hash.new
        }
        finding_data[:details].update(finding.details)

        if File.exists?(finding_file) then
          fh = File.new(finding_file, "w+b")
          fh.print YAML.dump(finding_data)
          fh.close
        end
      
    end

    # add_scan_log
    # adds a chat to a specific log store, e.g. if you want to log scan results.
    # needs a scan_name (STRING) as its destination which will be created
    # if the scan name does not exist.
    def add_scan_log(chat, scan_name = nil)
      begin
        return false if scan_name.nil?
        puts ">> scan_name"
        path = File.join(@scanlog_path, scan_name)
        
        Dir.mkdir path unless File.exist? path
        
        log_file = File.join( path, "log_" + Time.now.to_f.to_s)

        chat_data = {
          :request => chat.request.map{|x| x.inspect},
          :response => chat.response.map{|x| x.inspect},
        }
        puts log_file
        chat_data.update(chat.settings)
        File.open(log_file, "w") { |fh|
          YAML.dump(chat_data, fh)
        }
      return true
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return false
    end

    def add_chat(chat)
      chat_file = File.join("#{@conversation_path}", "#{chat.id}-chat")
      chat_data = {
        :request => chat.request.map{|x| x.inspect},
        :response => chat.response.map{|x| x.inspect},
      }

      chat_data.update(chat.settings)
      if not File.exists?(chat_file) then
        File.open(chat_file, "w") { |fh|
          YAML.dump(chat_data, fh)
        }
      chat.file = chat_file
      end
    end

    def each_chat(&block)
      get_file_list(@conversation_path, "*-chat").each do |fname|
        chat = Watobo::Utils.loadChatYAML(fname)
        next unless chat
        yield chat if block_given?
      end
    end

    def each_finding(&block)
      get_file_list(@findings_path, "*-finding").each do |fname|
        f = Watobo::Utils.loadFindingYAML(fname)
        next unless f
        yield f if block_given?
      end
    end

    

    def initialize(project_name, session_name)

      wsp = Watobo.workspace_path
      return false unless File.exist? wsp
      puts "* using workspace path: #{wsp}" if $DEBUG
      project_path = File.join(wsp, project_name)
      unless File.exist? project_path
        puts "* create project path: #{project_path}" if $DEBUG
        Dir.mkdir(project_path)
      end
      session_path = File.join(project_path, session_name)

      unless File.exist? session_path
        puts "* create session path: #{session_path}" if $DEBUG
        Dir.mkdir(session_path)
      end
      sext = Watobo::Conf::General.session_settings_file_ext
      
      @session_file = File.join(session_path, session_name + sext)
      @project_file = File.join(project_path, project_name + Watobo::Conf::General.project_settings_file_ext)

      @conversation_path = File.expand_path(File.join(session_path, Watobo::Conf::Datastore.conversations))

      @findings_path = File.expand_path(File.join(session_path, Watobo::Conf::Datastore.findings))
      @log_path = File.expand_path(File.join(session_path, Watobo::Conf::Datastore.event_logs_dir))
      @scanlog_path = File.expand_path(File.join(session_path, Watobo::Conf::Datastore.scan_logs_dir))

      [ @conversation_path, @findings_path, @log_path, @scanlog_path ].each do |folder|
        if not File.exists?(folder) then
          puts "create path #{folder}"
          begin
            Dir.mkdir(folder)
          rescue SystemCallError => bang
            puts "!!!ERROR:"
            puts bang
          rescue => bang
            puts "!!!ERROR:"
            puts bang
          end
        end
      end

    #     @chat_files = get_file_list(@conversation_path, "*-chat")
    #     @finding_files = get_file_list(@findings_path, "*-finding")
    end

    
    def save_session_settings(session_settings)
      
    end
    
    def load_session_settings()
      
    end
    
    def save_project_settings(project_settings)
      
    end
    
    def load_project_settings()
      
    end
    
    private
    
    def get_file_list(path, pattern)
      Dir["#{path}/#{pattern}"].sort_by{ |x| File.basename(x).sub(/[^0-9]*/,'').to_i }
    end
    
  end

end