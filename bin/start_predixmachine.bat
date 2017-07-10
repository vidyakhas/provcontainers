@ECHO OFF
REM Copyright (c) 2012-2016 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL

SET PREDIX_MACHINE_HOME=%~dp0..
REM Data Directory
IF DEFINED PREDIX_MACHINE_DATA_DIR (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_DATA_DIR:"=%
    REM " Clear quotation highlighting in editors
) ELSE (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_HOME%
)

SET START_PREDIX_MACHINE_LOG=%PREDIX_MACHINE_DATA%\logs\machine\start_predixmachine.log
TYPE NUL > "%START_PREDIX_MACHINE_LOG%"
CD "%PREDIX_MACHINE_HOME%"

SET ROOT=false
:CHECKARGS 
IF "%1" == "" (
	GOTO :ENDCHECKARGS
) ELSE (
	IF "%1" == "--force-root" (
		SET ROOT=true
	) ELSE (
		CALL :USAGE
		EXIT /B 1
	)
	SHIFT
)
GOTO :CHECKARGS
:ENDCHECKARGS

REM NET SESSION is a command that is only available to system administrators, so we use this to determine privilege.
NET SESSION > NUL 2>&1
IF %ERRORLEVEL% EQU 0 (
  	IF "%ROOT%" == "false" (
		CALL :WRITECONSOLELOG "Predix Machine should not be run as admin.  We recommend you create a low privileged predixmachineuser, allowing them only the required admin privileges to execute machine.  Bypass this error message with the argument --force-root"
  		EXIT /B 1
  	)
)

CALL :WRITECONSOLELOG "Starting Predix Machine."

IF EXIST "%PREDIX_MACHINE_HOME%\yeti\start_yeti.bat" (
	CMD /C "%PREDIX_MACHINE_HOME%\yeti\start_yeti.bat"
	GOTO :EOF
)
IF EXIST "%PREDIX_MACHINE_HOME%\machine\bin\predix\start_container.bat" (
	CMD /C "%PREDIX_MACHINE_HOME%\machine\bin\predix\start_container.bat"
	GOTO :EOF
) ELSE (
	CALL :WRITECONSOLELOG "The directory structure was not recognized.  Predix Machine could not be started."
	EXIT /B 1
)

:EOF
EXIT /B

:USAGE
    ECHO usage: start_yeti.bat [--force-root]
    ECHO     --force-root    Allow container to be run with elevated administrator privileges. Not recommended.
    EXIT /B

:TIMESTAMP
	SET RUNTIME=%date:~4,10% %time:~0,8%
	EXIT /B

:WRITECONSOLELOG
	CALL :TIMESTAMP
	ECHO %RUNTIME% %~1 >> "%START_PREDIX_MACHINE_LOG%"
	ECHO %RUNTIME% %~1
	EXIT /B