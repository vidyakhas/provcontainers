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

SET START_CONTAINER=%PREDIX_MACHINE_HOME%\machine\bin\predix\start_container.bat

REM Check the environment for the PREDIXMACHINELOCK variable.  If not set use the security directory.
IF NOT DEFINED PREDIXMACHINELOCK (
    SET PREDIXMACHINELOCK=%PREDIX_MACHINE_DATA%\security
)

REM The stop signal is used to indicate the watchdog loop should exit.
SET WATCHDOG_STOP_SIGNAL=%PREDIXMACHINELOCK%\stop_watchdog

REM Sets the watchdog environmental variable that is passed to the Java process.  This is used
REM by the framework to indicate if the framework will be restarted if shutdown.
SET PREDIX_MACHINE_WATCHDOG=started

REM Restart loop to keep the container running as long as the WATCHDOG_STOP_SIGNAL doesn't exist
:KEEPOPEN
CALL :WRITECONSOLELOG "Watchdog starting framework..."
CMD /C "%START_CONTAINER%"
CALL :WRITECONSOLELOG "Framework was shutdown."
IF NOT EXIST "%WATCHDOG_STOP_SIGNAL%" (
	REM Windows lacks a timeout that doesn't allow input redirection so use ping instead
	PING 127.0.0.1 -n 5 >NUL
	GOTO :KEEPOPEN
)

DEL /Q "%WATCHDOG_STOP_SIGNAL%"
ENDLOCAL
EXIT 0

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