@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL
PUSHD .
CD %~dp0..\..\..
SET PREDIX_MACHINE_HOME=%cd%

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

IF NOT EXIST "%PREDIXMACHINELOCK%\lock" (
	CALL :WRITECONSOLELOG "Lock file not found at %PREDIXMACHINELOCK%\lock. Predix Machine is not running"
	EXIT /B 1
)

SET SHUTDOWNCLIENT=%PREDIX_MACHINE_DATA%\machine\bin\predix\com.ge.dspmicro.shutdown-hook-client-17.1.0.jar
SET SECURITYADMIN=%PREDIX_MACHINE_DATA%\machine\bundles\com.ge.dspmicro.securityadmin-17.1.0.jar

SET SHUTDOWNCHECKCNT=1
:SHUTDOWN
	IF %SHUTDOWNCHECKCNT% GEQ 60 (
		CALL :WRITECONSOLELOG "Error: Could not initiate connection with shutdown hook server."
		GOTO :ENDSHUTDOWN
	)
	REM The secretkey_keystore is created on startup of the framework for the first time
	IF NOT EXIST "%PREDIX_MACHINE_DATA%\security\secretkey_keystore.jceks" (
		CALL :WRITECONSOLELOG "Framework has not started yet."
		REM Windows lacks a timeout that doesn't redirect input so use ping instead
		PING 127.0.0.1 -n 3 >NUL 
		SET /A SHUTDOWNCHECKCNT+=1
		GOTO :SHUTDOWN		
	)
	REM Calling the shutdown hook client jar sends a shutdown signal to the framework
	CALL java -cp "%SHUTDOWNCLIENT%";"%SECURITYADMIN%" com.ge.dspmicro.shutdownhookclient.ShutdownHookClient
	IF "%ERRORLEVEL%" NEQ "0" (
		CALL :WRITECONSOLELOG "Attempting to contact the shutdown hook server..."
		REM Windows lacks a timeout that doesn't redirect input so use ping instead
		PING 127.0.0.1 -n 3 >NUL
		SET /A SHUTDOWNCHECKCNT+=1
		GOTO :SHUTDOWN
	) ELSE (
		CALL :WRITECONSOLELOG "Shutdown signal sent successfully."
	)
:ENDSHUTDOWN

SET SHUTDOWNCHECKCNT=1
:SHUTDOWNCHECK
	IF %SHUTDOWNCHECKCNT% GEQ 180 (
		CALL :WRITECONSOLELOG "Error: Framework shutdown took longer than 3 minutes."
		EXIT /B 1
	)
	REM The start_container script will remove the lock file when it completes
	IF EXIST "%PREDIXMACHINELOCK%\lock" (
		REM Windows lacks a timeout that doesn't redirect input so use ping instead
		PING 127.0.0.1 -n 1 >NUL
		SET /A SHUTDOWNCHECKCNT+=1
		GOTO :SHUTDOWNCHECK
	)
CALL :WRITECONSOLELOG "Framework has shutdown."
POPD
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