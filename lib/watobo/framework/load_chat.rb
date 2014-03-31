# .
# load_chat.rb
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
  def self.load_chat(project, session, chat_id)
    path = File.join Watobo.workspace_path, project.to_s, session.to_s, Watobo::Conf::Datastore.conversations
    unless File.exist? path
      puts "Could not find conversation path for #{project}/#{session} in #{Watobo.workspace_path}"
      return nil
    end
    chat_file = "#{chat_id}-chat.yml"
    chat = Watobo::Utils.loadChatYAML File.join(path, chat_file)
    puts chat.class
    chat
    
  end
end