@ECHO OFF
REM Copyright (c) 2012-2017 General Electric Company. All rights reserved.
REM The copyright to the computer software herein is the property of
REM General Electric Company. The software may be used and/or copied only
REM with the written permission of General Electric Company or in accordance
REM with the terms and conditions stipulated in the agreement/contract
REM under which the software has been supplied.

SETLOCAL EnableDelayedExpansion

REM This logic block is used when this script calls itself.  This is done to allow for an exit trap on an interrupt
IF "%~1" EQU "_START_" (
	GOTO :UPDATEPOLL
)

:INITIALIZE
PUSHD .
CD %~dp0..
SET PREDIX_MACHINE_HOME=%cd%
POPD

REM Data Directory
IF DEFINED PREDIX_MACHINE_DATA_DIR (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_DATA_DIR:"=%
	REM " Clear quotation highlighting in editors
) ELSE (
    SET PREDIX_MACHINE_DATA=%PREDIX_MACHINE_HOME%
)

REM Check the environment for the PREDIXMACHINELOCK variable.  If not set use the security directory.
IF NOT DEFINED PREDIXMACHINELOCK (
    SET PREDIXMACHINELOCK=%PREDIX_MACHINE_DATA%\security
)

REM The stop signal is used to indicate the Yeti loop should exit.
SET YETI_STOP_SIGNAL=%PREDIXMACHINELOCK%\stop_yeti
SET WATCHDOG_STOP_SIGNAL=%PREDIXMACHINELOCK%\stop_watchdog
REM Cleanup old stop signals
DEL /Q "%YETI_STOP_SIGNAL%" 2> NUL
DEL /Q "%WATCHDOG_STOP_SIGNAL%" 2> NUL

SET PF_APPDATA=%PREDIX_MACHINE_DATA%\appdata\packageframework
IF NOT EXIST "%PF_APPDATA%" (
	MKDIR "%PF_APPDATA%"
)

title=Yeti - start_yeti.bat
SET RUNDATE=%date:~-10,2%%date:~-7,2%%date:~-2,4%%time:~-11,2%%time:~-8,2%%time:~-5,2%
SET TEMPDIR=%USERPROFILE%\AppData\Local\Temp
SET START_PREDIX_MACHINE_LOG=%PREDIX_MACHINE_DATA%\logs\machine\start_predixmachine.log
REM The Package Framework directory where JSON files are picked up.
SET PACKAGEFRAMEWORK=%PREDIX_MACHINE_DATA%\appdata\packageframework

REM The validate start script checks for the java keytool and that no other containers are running
CALL "%PREDIX_MACHINE_HOME%\machine\bin\predix\validate_start.bat"
IF %ERRORLEVEL% NEQ 0 (
    EXIT /B 1
)


REM Checks the directory structure for the watchdog, which is required for updates.
IF NOT EXIST "%PREDIX_MACHINE_DATA%\yeti\watchdog\start_watchdog.bat" (
	CALL :TIMESTAMP
	CALL :WRITECONSOLELOG "The watchdog does not exist at %PREDIX_MACHINE_DATA%\yeti\watchdog.  This is required for Yeti."
	EXIT /B 1
)
REM Startup watchdog
CMD /C START "Predix Machine Watchdog" "%PREDIX_MACHINE_DATA%\yeti\watchdog\start_watchdog.bat"

(	REM Put this in a code block (the parentheses) so it will not be stopped by a ctrl+c
	CALL :WRITECONSOLELOG "Watchdog started, ready to install new packages."
	CMD /C "%~f0" _START_ %*
	CALL :FINISH
	EXIT /B
)

:UPDATEPOLL
	IF EXIST "%YETI_STOP_SIGNAL%" (
		EXIT /B
	)
	REM Check the installations directory for new package files.
	IF EXIST "%PREDIX_MACHINE_DATA%\installations\*.zip" (
		CD "%PREDIX_MACHINE_DATA%"
		FOR %%F IN ("%PREDIX_MACHINE_DATA%\installations\*.zip") DO (
			REM Verify the zip
			SET UNZIPDIR=%TEMPDIR%\%%~NF
			SET ZIP=%%F
			SET ZIPNAME=%%~NF
			SET WAITCNT=0
			REM Wait for the associated zip.sig file to be present.  Each package should have this, it is required for verification.
			:WAITFORSIG
				IF !WAITCNT! GEQ 12 (
					SET MESSAGE=No signature file found for associated zip. Package origin could not be verified.
					SET ERRORCODE=21
					CALL :WRITEFAILUREJSON
					CALL :INSTALLCOMPLETE "failed "
					GOTO :UPDATEPOLL
				)
				IF NOT EXIST "!ZIP!.sig" (
					REM Windows lacks a timeout that doesn't allow input redirection so use ping instead
					PING 127.0.0.1 -n 5 >NUL
					SET /A WAITCNT+=1
					GOTO :WAITFORSIG
				)
			SET JAR=%PREDIX_MACHINE_DATA%\yeti\com.ge.dspmicro.yetiappsignature-17.1.0.jar


			REM Windows lacks a timeout that doesn't allow input redirection so use ping instead
			PING 127.0.0.1 -n 5 >NUL
			IF EXIST "!UNZIPDIR!" (
                RMDIR /S /Q "!UNZIPDIR!" >>"%START_PREDIX_MACHINE_LOG%" 2>&1
            )
            MKDIR "!UNZIPDIR!"
            CD "!UNZIPDIR!"

            REM Run the verification process using the package.zip and package.zip.sig
			CALL java -Xmx25m -jar "!JAR!" "%PREDIX_MACHINE_DATA%" "!ZIP!">>"%START_PREDIX_MACHINE_LOG%" 2>&1
			IF !ERRORLEVEL! NEQ 0 (
			 	SET MESSAGE=Package origin was not verified to be from the Predix Cloud. Installation failed.
				SET ERRORCODE=22
				CALL :WRITEFAILUREJSON
				CALL :INSTALLCOMPLETE "failed "
				GOTO :UPDATEPOLL
			) ELSE (
			CALL :WRITECONSOLELOG "Package origin has been verified. Continuing installation."
			)

			CD "%TEMPDIR%"
			REM Yeti only supports a single directory per installation zip, count the number of directories
			SET CNT=0
			FOR /D %%A IN ("!UNZIPDIR!\*") DO (
				SET APPNAME=%%A
				SET /A CNT+=1
			)
			REM Applications can have an install script at the top level or directly in the application directory
			IF NOT EXIST "!UNZIPDIR!\install\install.bat" (
				IF !CNT! NEQ 1 (
					SET MESSAGE=Incorrect zip format.  Applications should be a single folder with the packagename\\install\\install.sh structure, zipped with Windows zip utility.
					SET ERRORCODE=24
					CALL :WRITEFAILUREJSON
					CALL :INSTALLCOMPLETE "failed "
					GOTO :UPDATEPOLL
				)
				IF NOT EXIST "!APPNAME!\install\install.bat" (
					SET MESSAGE=Incorrect zip format.  Applications should be a single folder with the packagename\\install\\install.sh structure, zipped with Windows zip utility.
					SET ERRORCODE=24
					CALL :WRITEFAILUREJSON
					CALL :INSTALLCOMPLETE "failed "
					GOTO :UPDATEPOLL
				)
				COPY "!APPNAME!\install\install.bat" "!UNZIPDIR!\install.bat" /Y /V >>"%START_PREDIX_MACHINE_LOG%" 2>&1
			) ELSE (
				COPY "!UNZIPDIR!\install\install.bat" "!UNZIPDIR!\install.bat" /Y /V >>"%START_PREDIX_MACHINE_LOG%" 2>&1
			)
			CALL :WRITECONSOLELOG "Running the !ZIPNAME! install script..."
			CALL "%PREDIX_MACHINE_HOME%"\yeti\lib\DateAndTime.bat :GetEpochTime epoch
			ECHO startTimestamp=!epoch! > "%PF_APPDATA%\!ZIPNAME!.properties"
			CD !UNZIPDIR!
			CMD /C install.bat "%PREDIX_MACHINE_DATA%" "!UNZIPDIR!" "!ZIPNAME!"
			SET ERRORCODE=!ERRORLEVEL!
			CALL "%PREDIX_MACHINE_HOME%"\yeti\lib\DateAndTime.bat :GetEpochTime epoch
			ECHO endTimestamp=!epoch! >> "%PF_APPDATA%\!ZIPNAME!.properties"
			CD "%PREDIX_MACHINE_DATA%"
			IF !ERRORCODE! EQU 100 (
				REM Error code 100 used to skip yeti checks for success, only to be used when certain package will succeed.
				CALL :INSTALLCOMPLETE "failed "
				GOTO :UPDATEPOLL
			)
			IF !ERRORCODE! NEQ 0 (
				IF EXIST "%PACKAGEFRAMEWORK%\!ZIPNAME!.json" (
					SET MESSAGE=Installation of !ZIPNAME! failed. Error Code: !ERRORCODE!
					CALL :INSTALLCOMPLETE "failed "
					GOTO :UPDATEPOLL
				)
			)
			IF !ERRORCODE! NEQ 0 (
				SET MESSAGE=An error occurred while running the install script. Error Code: !ERRORCODE!
				CALL :WRITEFAILUREJSON
				CALL :INSTALLCOMPLETE "failed "
				GOTO :UPDATEPOLL
			)
			IF NOT EXIST "%PACKAGEFRAMEWORK%\!ZIPNAME!.json" (
				SET ERRORCODE=53
				SET MESSAGE=The !ZIPNAME! installation script did not produce a JSON result to verify its completion.  Installation status unknown. Error Code: !ERRORCODE!
				CALL :WRITEFAILUREJSON
				CALL :INSTALLCOMPLETE "failed "
				GOTO :UPDATEPOLL
			)
			REM Need to check for successful connection to cloud
			CALL :CHECKCONNECTION
		)
		CALL :WRITECONSOLELOG "Done."
	) ELSE (
		REM Windows lacks a timeout that doesn't allow input redirection so use ping instead
		PING 127.0.0.1 -n 5 >NUL
	)
	GOTO :UPDATEPOLL

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

REM This function cleans up after a failed install by removing the downloaded zip and temporary files.
:INSTALLCOMPLETE
	MOVE "!ZIP!.sig" %PF_APPDATA%
	DEL /Q "!ZIP!" >>"%START_PREDIX_MACHINE_LOG%" 2>&1
	RMDIR /S /Q "!UNZIPDIR!" >>"%START_PREDIX_MACHINE_LOG%" 2>&1
	CALL :WRITECONSOLELOG "!MESSAGE!"
	CALL :TIMESTAMP
	ECHO %RUNTIME% ##########################################################################>> "%START_PREDIX_MACHINE_LOG%"
	ECHO %RUNTIME% #                           Installation %~1                         #>> "%START_PREDIX_MACHINE_LOG%"
	ECHO %RUNTIME% ##########################################################################>> "%START_PREDIX_MACHINE_LOG%"
	CALL :WRITECONSOLELOG "Done."
	EXIT /B

REM This function writes a JSON to the appdata/packageframework directory to indicate installation failure
:WRITEFAILUREJSON
	(
	ECHO {
	ECHO     "status" : "failure",
	ECHO     "errorcode" : %ERRORCODE%,
	ECHO     "message" : "%MESSAGE%"
	ECHO }
	) > "%PREDIX_MACHINE_DATA%\appdata\packageframework\%ZIPNAME%.json"
	EXIT /B

REM This function monitors the JSON file produced by an installation for it to be picked up by the Package Framework service
REM If the file is removed by the service, the cloud connection is confirmed.  If not we assume the container
REM could not reconnect and rollback the update.
:CHECKCONNECTION
	SET CONNCHECKCNT=0
	FOR /F "tokens=2 delims==" %%a IN ('find "rollbackWaitDuration" ^<"%PREDIX_MACHINE_HOME%\configuration\yeti\yeti.cfg"') DO SET MAXCONNECT=%%a
	SET "INTEGER="&for /f "delims=0123456789" %%a in ("%MAXCONNECT%") do set INTEGER=%%a
	IF DEFINED INTEGER (
		ECHO rollbackWaitDuration is not an integer or is negative. Defaulting to 600 seconds.
		SET MAXCONNECT=600
	) ELSE (
		ECHO rollbackWaitDuration is %MAXCONNECT%
	)
	SET /A MAXCONNECT=%MAXCONNECT%/5
	:CONNECTIONLOOP
		IF !CONNCHECKCNT! GEQ %MAXCONNECT% (
			CALL :WRITECONSOLELOG "Error: Predix Machine did not reconnect to cloud after update. Rolling back update."
			CALL :WRITECONSOLELOG "Installation of !ZIPNAME! was unsuccessful."
			SET ERRORCODE=52
			SET MESSAGE=Predix Machine did not reconnect to cloud after !ZIPNAME! installation. Error Code: !ERRORCODE!
			CALL :ROLLBACK
			CALL :WRITEFAILUREJSON
			CALL :INSTALLCOMPLETE "failed "
			GOTO :ENDCONNECTIONLOOP
		)
		IF EXIST "%PACKAGEFRAMEWORK%\!ZIPNAME!.json" (
			CALL :WRITECONSOLELOG "Checking for connection to cloud..."
			PING 127.0.0.1 -n 5 >NUL
			SET /A CONNCHECKCNT+=1
			GOTO :CONNECTIONLOOP
		)
		CALL :WRITECONSOLELOG "Connection to cloud was successful."
		SET MESSAGE=Installation of !ZIPNAME! was successful.
		CALL :INSTALLCOMPLETE "success"
	:ENDCONNECTIONLOOP
	EXIT /B

REM This function is used to rollback the previous installation.
:ROLLBACK
	FOR %%A in (%APPNAME%) DO SET NEWAPP=%%~NA
	IF EXIST "%PREDIX_MACHINE_DATA%\%NEWAPP%.old" (
		CMD /C "%PREDIX_MACHINE_DATA%\yeti\watchdog\stop_watchdog.bat"
		RMDIR /S /Q "%PREDIX_MACHINE_DATA%\%NEWAPP%"
		REN "%NEWAPP%.old" "%NEWAPP%" >> "%START_PREDIX_MACHINE_LOG%" 2>&1
		IF %ERRORLEVEL% EQU 0 (
			CALL :WRITECONSOLELOG "Rollback successful."
			SET MESSAGE=%MESSAGE%. Rollback successful.
		) ELSE (
			CALL :WRITECONSOLELOG "Rollback unsuccessful."
			SET MESSAGE=%MESSAGE%. Rollback unsuccessful.
		)
		CMD /C START "Predix Machine Watchdog" "%PREDIX_MACHINE_DATA%\yeti\watchdog\start_watchdog.bat"
	)
	EXIT /B

REM This function is used as an exit trap to ensure the framework is shutdown and clean up and stop signals.
:FINISH
	REM Cleanup after Yeti exits
	CALL :WRITECONSOLELOG "Yeti is shutting down."
	CD "%PREDIX_MACHINE_DATA%"
	CALL "%PREDIX_MACHINE_DATA%\yeti\watchdog\stop_watchdog.bat"
	IF EXIST "%YETI_STOP_SIGNAL%" (
		DEL "%YETI_STOP_SIGNAL%"
	)
	CALL :WRITECONSOLELOG "Shutdown complete."
	ENDLOCAL
	EXIT /B