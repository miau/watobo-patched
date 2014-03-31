# .
# constants.rb
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
$debug_project = false
$debug_active_check = false
$debug_scanner = false


# @private 
module Watobo#:nodoc: all
  module Constants    
    CHAT_SOURCE_UNDEF = 0x00
    CHAT_SOURCE_INTERCEPT = 0x01
    CHAT_SOURCE_PROXY = 0x02
    CHAT_SOURCE_MANUAL = 0x03
    CHAT_SOURCE_FUZZER = 0x04
    CHAT_SOURCE_MANUAL_SCAN = 0x05
    CHAT_SOURCE_AUTO_SCAN = 0x06
    
    FINDING_TYPE_UNDEFINED = 0x00
    FINDING_TYPE_INFO = 0x03
    FINDING_TYPE_HINT = 0x01
    FINDING_TYPE_VULN = 0x02
    
    VULN_RATING_UNDEFINED = 0x00
    VULN_RATING_INFO = 0x01
    VULN_RATING_LOW = 0x02
    VULN_RATING_MEDIUM = 0x03
    VULN_RATING_HIGH = 0x04
    VULN_RATING_CRITICAL = 0x05
    
    # ActiveCheck Groups
    AC_GROUP_GENERIC = "Generic"
    AC_GROUP_SQL = "SQL-Injection"
    AC_GROUP_XSS = "XSS"
    AC_GROUP_ENUMERATION = "Enumeration"
    AC_GROUP_FILE_INCLUSION = "File Inclusion"
    
    AC_GROUP_DOMINO = "Lotus Domino"
    AC_GROUP_SAP = "SAP"
    AC_GROUP_TYPO3 = "Typo3"
    AC_GROUP_JOOMLA = "Joomla"
    AC_GROUP_JBOSS = "JBoss AS"
    AC_GROUP_FLASH = "Flash"
    AC_GROUP_APACHE = "Apache"
    
    ICON_PATH = "icons"
    
    FIRST_TIME_FILE = "first_time_file"  
    
    # Transfer Encoding Types
    TE_NONE = 0x00
    TE_CHUNKED = 0x01
    TE_COMPRESS = 0x02
    TE_GZIP = 0x04
    TE_DEFLATE = 0x08
    TE_IDENTITY = 0x10
    
    # Log Level
    LOG_INFO = 0x00
    LOG_DEBUG = 0x01
    
    # Authentication Types
    AUTH_TYPE_NONE =   0x00
    AUTH_TYPE_BASIC =  0x01
    AUTH_TYPE_DIGEST = 0x02
    AUTH_TYPE_NTLM =   0x04
    AUTH_TYPE_UNKNOWN = 0x10
    
    GUI_SMALL_FONT_SIZE = 7
    GUI_REGULAR_FONT_SIZE = 9
    
    DEFAULT_PORT_HTTP = 80
    DEFAULT_PORT_HTTPS = 443
    
    # Status Messages
    SCAN_STARTED = 0x00
    SCAN_FINISHED = 0x01
    SCAN_PAUSED = 0x02
    SCAN_CANCELED = 0x04
  end
end
