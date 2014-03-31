# .
# save_default_settings.rb
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

  module Gui
    def self.save_settings()
      begin

        mp = ''
        save_pws = false

        #   puts "= Master Password Settings ="
        #   puts Watobo::Gui::MasterPW.settings.to_yaml

        if Watobo::Gui::MasterPW.save_passwords?
          save_pws = true
          unless Watobo::Gui::MasterPW.set?
            save_pws = false unless Watobo::Gui::MasterPW.save_without_master?
          end
        end

        Watobo.save_proxy_settings( :save_passwords => save_pws, :key => mp )

        Watobo::Gui.save_scanner_settings()
        unless Watobo.project.nil?
          Watobo::Conf::General.save_project(Watobo.project.session_store)
          Watobo::Conf::Interceptor.save_project(Watobo.project.session_store)
        end
        # also save global settings here
        Watobo::Conf::General.save
        Watobo::Conf::Interceptor.save

        return true
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return false
    end

    def self.save_default_settings_UNUSED(project)
      mp = ''
      save_pws = false

      #  puts "= Master Password Settings ="
      #  puts Watobo::Gui::MasterPW.settings.to_yaml

      if Watobo::Gui::MasterPW.save_passwords?
        save_pws = true
        unless Watobo::Gui::MasterPW.set?
          save_pws = false unless Watobo::Gui::MasterPW.save_without_master?
        end
      end

      Watobo.save_proxy_settings( :save_passwords => save_pws, :key => mp )

      Watobo::Conf::General.save
      Watobo::Conf::Interceptor.save

      return true
=begin
    proxy_has_credentials = false

    settings[:forwarding_proxy].each_key do |p|
    next if p == :default_proxy
    proxy = settings[:forwarding_proxy][p]

    if proxy.has_key? :password and proxy[:password] != ''
    #       puts " - proxy #{p} has password #{proxy_list[p][:credentials][:password]}"
    proxy_has_credentials = true
    end
    end
    end

    if proxy_has_credentials == true
    if settings[:password_policy][:save_passwords] == true
    if settings[:password_policy][:save_without_master] == false
    if Watobo::Gui.master_password.empty?
    # puts "* need master password for proxy"
    dlg = MasterPWDialog.new(self)
    if dlg.execute != 0
    Watobo::Gui.master_password = dlg.masterPassword
    end
    end
    unless Watobo::Gui.master_password.empty?
    settings[:forwarding_proxy].each_key do |p|
    #creds = settings[:forwarding_proxy][p][:credentials]
    #pass = "$$WPE$$" + creds[:password]
    pass = settings[:forwarding_proxy][p][:password]
    unless pass.empty?
    creds[:password] = Crypto.encryptPassword(pass, Watobo::Gui.master_password)
    creds[:encrypted] = true
    end
    end
    else
    cleanCredentials(settings)
    FXMessageBox.information(self,MBOX_OK,"No MasterPassword", "Could not encrypt proxy passwords. No Passwords have been saved!")
    end
    else
    puts "* saving passwords without protection!!!!"
    end
    else
    cleanCredentials(settings)
    end
    # puts "=== DEFAULT SETTINGS PASSWORD POLICY"
    # puts YAML.dump(settings)
    Watobo::Utils.save_settings(@default_settings_file, settings )
=end

    end

  end

end
