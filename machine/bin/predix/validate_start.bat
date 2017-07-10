@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL
SET PREDIX_MACHINE_HOME=%~dp0..\..\..

IF NOT DEFINED JAVA_HOME (
	CALL :WRITECONSOLELOG "JAVA_HOME not set. Please set the JAVA_HOME variable to point to the location where Java is installed."
	EXIT /B 1
)

REM Data Directory
IF DEFINED PREDIX_MACHINE_DATA_DIR (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_DATA_DIR:"=%
	REM " Clear quotation highlighting in editors
) ELSE (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_HOME%
)
REM Exit if lock file exists
IF NOT DEFINED PREDIXMACHINELOCK (
    SET PREDIXMACHINELOCK=%PREDIX_MACHINE_DATA%\security
)
SET START_PREDIX_MACHINE_LOG=%PREDIX_MACHINE_DATA%\logs\machine\start_predixmachine.log

REM Exit if keytool is not installed.
where keytool >nul 2>nul
if %errorlevel%==1 (
    CALL :WRITECONSOLELOG "Java keytool not found. Exiting."
    EXIT /B 1
)

REM Exit if another instance of Predix Machine is running
SET PORT=45361
FOR /F "tokens=2 skip=1 delims==" %%A in ('find /i "com.ge.dspmicro.securityadmin.server.port" "%PREDIX_MACHINE_DATA%\security\com.ge.dspmicro.securityadmin.cfg"') DO (
	SET PORT=%%A
)
SET PORT=%PORT: =%

netstat -na | find "0.0.0.0:%PORT%"

IF %ERRORLEVEL% EQU 0 (
	CALL :WRITECONSOLELOG "Port conflict on localhost:%PORT%. Either another instance of Predix Machine is running or another application is bound to the port.  Change the com.ge.dspmicro.securityadmin.server.port property in security\com.ge.dspmicro.securityadmin.cfg"
    EXIT /B 1
)

IF EXIST "%PREDIXMACHINELOCK%\lock" (
    CALL :WRITECONSOLELOG "Predix Machine lock file exists at %PREDIXMACHINELOCK%\lock.  Either another instance of Predix Machine is running, or the last instance was shutdown incorrectly."
    EXIT /B 1
)
ENDLOCAL
EXIT /B 0

:TIMESTAMP
	SET RUNTIME=%date:~4,10% %time:~0,8%
	EXIT /B

:WRITECONSOLELOG
	CALL :TIMESTAMP
	ECHO %RUNTIME% %~1 >> "%START_PREDIX_MACHINE_LOG%"
	ECHO %RUNTIME% %~1
	EXIT /B