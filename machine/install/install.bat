@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

REM Updating the %APPLICATION% application proceeds as follows:
REM This script is triggered by yet when an zip is placed in the installation
REM directory.

REM 1. Make a backup of previous %APPLICATION% application
REM 2. Add new %APPLICATION% application
REM 3. Return an error code or 0 for success

SETLOCAL EnableDelayedExpansion
REM PREDIX_MACHINE_HOME - path to the container surrounded by quotes, passed in by yeti
SET PREDIX_MACHINE_HOME=%1
REM UPDATEDIR - path to the new %APPLICATION% surrounded by quotes, passed in by yeti
SET UPDATEDIR=%2
REM ZIPNAME - the name of the zip file being installed surrounded by quotes. Write a json file to
REM appdata\packageframework to give the package status
SET ZIPNAME=%~3
SET APPLICATION=machine
SET RUNDATE=%date:~-10,2%%date:~-7,2%%date:~-2,4%%time:~-11,2%%time:~-8,2%%time:~-5,2%
SET LOG="%PREDIX_MACHINE_HOME%"\logs\installations\%ZIPNAME%.log

:APPLICATIONINSTALL
	ECHO ##########################################################################>"%LOG%"
	ECHO #                 Shutting down container for update                     #>>"%LOG%"
	ECHO ##########################################################################>>"%LOG%"
	CMD /C "%PREDIX_MACHINE_HOME%"\yeti\watchdog\stop_watchdog.bat

	REM Update the application by removing any old backups, renaming the
	REM current installed application to %APPLICATION%.old, and adding the updated %APPLICATION%
	REM applications
	CD "%PREDIX_MACHINE_HOME%"
	CALL :WRITECONSOLELOG "Updating the %APPLICATION% directory."
	IF EXIST %APPLICATION%.old\ (
		CALL :WRITECONSOLELOG "Removing the %APPLICATION%.old application backup."
		RMDIR /Q /S %APPLICATION%.old>>"%LOG%" 2>&1
		IF !ERRORLEVEL! NEQ 0 (
			SET MESSAGE=Previous %APPLICATION%.old could not be removed. This is most likely due to another process.  Be sure no processes such as CMD or Explorer are holding resources in this directory.
			SET ERRORCODE=54
			SET STATUS=failure
			CALL :FINISH
		)
		IF EXIST %APPLICATION%.old\ (
			SET MESSAGE=Previous %APPLICATION%.old could not be removed. This is most likely due to another process.  Be sure no processes such as CMD or Explorer are holding resources in this directory.
			SET ERRORCODE=54
			SET STATUS=failure
			CALL :FINISH
		) ELSE (
			CALL :WRITECONSOLELOG "Previous %APPLICATION%.old removed."
		)
	)
	IF EXIST %APPLICATION%\ (
		CALL :WRITECONSOLELOG "Updating %APPLICATION% application. Backup of current application stored in %APPLICATION%.old."
		REN %APPLICATION% %APPLICATION%.old>>"%LOG%" 2>&1
		IF !ERRORLEVEL! NEQ 0 (
			SET MESSAGE=The %APPLICATION% application could not be backed up. This is most likely due to another process.  Be sure no processes such as CMD or Explorer are holding resources in this directory.
			SET ERRORCODE=55
			SET STATUS=failure
			CALL :FINISH
		)
		IF EXIST %APPLICATION%\ (
			SET MESSAGE=The %APPLICATION% application could not be backed up. This is most likely due to another process.  Be sure no processes such as CMD or Explorer are holding resources in this directory.
			SET ERRORCODE=55
			SET STATUS=failure
			CALL :FINISH
		) ELSE (
			CALL :WRITECONSOLELOG "The %APPLICATION% application backup was created as %APPLICATION%.old."
		)
	)
	MOVE "%UPDATEDIR%"\%APPLICATION% >>"%LOG%" 2>&1
	IF %ERRORLEVEL% NEQ 0 (
		SET MESSAGE=The %APPLICATION% application could not be updated.
		SET ERRORCODE=56
		SET STATUS=failure
		CALL :ROLLBACK "%APPLICATION%"
		CALL :FINISH
	)
	IF EXIST %APPLICATION%\ (
		SET MESSAGE=The %APPLICATION% application has been updated.
		SET ERRORCODE=0
		SET STATUS=success
		CALL :FINISH
	) ELSE (
		SET MESSAGE=The %APPLICATION% application could not be updated.
		SET ERRORCODE=56
		SET STATUS=failure
		CALL :ROLLBACK "%APPLICATION%"
		CALL :FINISH
	)
	EXIT /B

:ROLLBACK
	CALL :WRITECONSOLELOG "Update unsuccessful. Attempting to rollback."
	SET DIRECTORY=%1
	IF EXIST "%PREDIX_MACHINE_HOME%"\%DIRECTORY%\ (
		RMDIR /Q /S "%PREDIX_MACHINE_HOME%"\%DIRECTORY%>>"%LOG%" 2>&1
	)
	MOVE "%PREDIX_MACHINE_HOME%"\%DIRECTORY%.old "%PREDIX_MACHINE_HOME%"\%DIRECTORY%>>"%LOG%" 2>&1
	IF !ERRORLEVEL! NEQ 0 (
		CALL :WRITECONSOLELOG "Rollback unsuccessful."
	) ELSE (
		CALL :WRITECONSOLELOG "Rollback successful."
	)
	EXIT /B

:TIMESTAMP
	SET RUNTIME=%date:~4,10% %time:~0,8%
	EXIT /B

:WRITECONSOLELOG
	CALL :TIMESTAMP
	ECHO %RUNTIME% %~1 >> "%LOG%"
	ECHO %RUNTIME% %~1
	EXIT /B
	
:FINISH
	CD "%PREDIX_MACHINE_HOME%"
	CALL :WRITECONSOLELOG "Installation completed with errorcode !ERRORCODE!"
	CALL :WRITECONSOLELOG "!MESSAGE!"
	IF !ERRORCODE! EQU 0 (
		(
		ECHO {
		ECHO     "status" : "!STATUS!",
		ECHO     "message" : "!MESSAGE!"
		ECHO }
		) > appdata\packageframework\%ZIPNAME%.json
	) ELSE (
		(
		ECHO {
		ECHO     "status" : "!STATUS!",
		ECHO     "errorcode" : !ERRORCODE!,
		ECHO     "message" : "!MESSAGE!"
		ECHO }
		) > appdata\packageframework\%ZIPNAME%.json
	)
	CALL :WRITECONSOLELOG "Starting up the container..."
	CMD /C START "Predix Machine Watchdog" "%PREDIX_MACHINE_HOME%\yeti\watchdog\start_watchdog.bat"
	EXIT !ERRORCODE!