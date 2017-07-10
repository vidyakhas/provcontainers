@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL

SET PREDIX_MACHINE_HOME=%~dp0..
CD "%PREDIX_MACHINE_HOME%"

IF EXIST "%PREDIX_MACHINE_HOME%\yeti\stop_yeti.bat" (
	CMD /C "%PREDIX_MACHINE_HOME%\yeti\stop_yeti.bat"
	GOTO :EOF
)
IF EXIST "%PREDIX_MACHINE_HOME%\machine\bin\predix\stop_container.bat" (
	CMD /C "%PREDIX_MACHINE_HOME%\machine\bin\predix\stop_container.bat"
	GOTO :EOF
)

:EOF
ENDLOCAL