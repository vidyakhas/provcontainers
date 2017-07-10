@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL
SET PREDIX_MACHINE_HOME=%~dp0..\..
CD "%PREDIX_MACHINE_HOME%"

REM Data Directory
IF DEFINED PREDIX_MACHINE_DATA_DIR (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_DATA_DIR:"=%
    REM " Clear quotation highlighting in editors
) ELSE (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_HOME%
)
SET START_PREDIX_MACHINE_LOG=%PREDIX_MACHINE_DATA%\logs\machine\start_predixmachine.log

REM Check the environment for the PREDIXMACHINELOCK variable.  If not set use the security directory.
IF NOT DEFINED PREDIXMACHINELOCK (
    SET PREDIXMACHINELOCK=%PREDIX_MACHINE_DATA%\security
)
SET WATCHDOG_STOP_SIGNAL=%PREDIXMACHINELOCK%\stop_watchdog

ECHO > "%WATCHDOG_STOP_SIGNAL%"
CMD /C "%PREDIX_MACHINE_HOME%\machine\bin\predix\stop_container.bat"

SET SHUTDOWNCHECKCNT=1
:SHUTDOWNCHECK
	IF %SHUTDOWNCHECKCNT% GEQ 180 (
		CALL :WRITECONSOLELOG "Error: Shutdown took longer than 3 minutes."
		EXIT /B 1
	)
	REM The start_watchdog script will remove the stop signal when it completes
	IF EXIST "%WATCHDOG_STOP_SIGNAL%" (
		REM Windows lacks a timeout that doesn't redirect input so use ping instead
		PING 127.0.0.1 -n 1 > NUL
		SET /A SHUTDOWNCHECKCNT+=1
		GOTO :SHUTDOWNCHECK
	)
CALL :WRITECONSOLELOG "Watchdog has shutdown."

ENDLOCAL
EXIT /B 0

REM This function formats the timestamp for use by the WRITECONSOLELOG function.
:TIMESTAMP
	SET RUNTIME=%date:~4,10% %time:~0,8%
	EXIT /B

REM This function takes a string value, creates a timestamp, and writes it the log file as well as the console
:WRITECONSOLELOG
	CALL :TIMESTAMP
	ECHO %RUNTIME% %~1 >> "%START_PREDIX_MACHINE_LOG%"
	ECHO %RUNTIME% %~1
	EXIT /B