@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

NET SESSION > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
	ECHO Installing the Predix Machine Service requires system administrator privileges. Please try again with an elevated command prompt.
	EXIT /B
)

SET INSTALLUTIL=installutil.exe
where installutil >nul 2>nul
if %errorlevel%==1 (
	if exist "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe" (
		SET INSTALLUTIL=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe
	)
    CALL :WRITECONSOLELOG "InstallUtil not found. Install Util is part of .NET Framework 4.5.2, please install and add InstallUtil to the path.  Exiting."
    EXIT /B 1
)

set /p USERNAME="Enter logon username including domain e.g. domain\username : "
set /p PASSWORD="Enter password for logon username : "

SET SERVICE_INSTALL=%~dp0
CALL "%INSTALLUTIL%" /username=%USERNAME% /password=%PASSWORD% /unattended "%SERVICE_INSTALL%\PredixMachineService.exe"
IF %ERRORLEVEL% NEQ 0 (
	ECHO Predix Machine Service installation failed with an error. View the InstallUtil.InstallLog and PredixMachineService.InstallLog for more details.
) ELSE (
	ECHO Predix Machine Service installed successfully.
)