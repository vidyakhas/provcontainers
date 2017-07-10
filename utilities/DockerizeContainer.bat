@echo off

rem  Copyright (c) 2012-2016 General Electric Company. All rights reserved.
rem  The copyright to the computer software herein is the property of
rem  General Electric Company. The software may be used and/or copied only
rem  with the written permission of General Electric Company or in accordance
rem  with the terms and conditions stipulated in the agreement/contract
rem  under which the software has been supplied

setlocal EnableDelayedExpansion

rem Constants
set MACHINE_BUILD_VERSION=17.1.0
set DOCKER_FILE_PREFIX=Dockerfile-predixdtr-alpine
rem DO NOT CHANGE THE VALUE OF THIS VARIABLE. IT TAGS PREDIX MACHINE WITH THIS NAME. THE BOOTSTRAP REQUIRES THIS.
set DOCKER_IMAGE_PREFIX=predixmachine

rem Input Parameters and Defaults
set MACHINE_PATH=
set DOCKER_HOST=
set TAR_NAME=
set CONTAINER_NAME=default
set ARCHITECTURE=x86_64
set DOCKER_FTP_PROXY=
set DOCKER_HTTP_PROXY=
set DOCKER_HTTPS_PROXY=
set DOCKER_NO_PROXY=


echo.
echo Init environment ...
:InitEnvironment
    set ORIGINAL_DIR=%cd%
    echo ORIGINAL_DIR=%ORIGINAL_DIR%
    set SCRIPT_DIR=%~dp0
    echo SCRIPT_DIR=%SCRIPT_DIR%
:EndInitEnvironment


echo.
echo Parsing arguments ...
:ParseArguments
    if "%1"=="" goto EndParseArguments
    if "%1"=="-h" (
        call :Usage
        exit /b 0
    ) else if "%1"=="-m" (
        set MACHINE_PATH=%~f2
        shift
    ) else if "%1"=="--docker_host" (
        set DOCKER_HOST=%~2
        shift
    ) else if "%1"=="--container_name" (
        set CONTAINER_NAME=%~2
        shift
    ) else if "%1"=="--arch" (
        set ARCHITECTURE=%~2
        shift
    ) else if "%1"=="--tar_name" (
        set TAR_NAME=%~2
        shift
    ) else if "%1"=="--ftp_proxy" (
        set DOCKER_FTP_PROXY=%~2
        shift
    ) else if "%1"=="--http_proxy" (
        set DOCKER_HTTP_PROXY=%~2
        shift
    ) else if "%1"=="--https_proxy" (
        set DOCKER_HTTPS_PROXY=%~2
        shift
    ) else if "%1"=="--no_proxy" (
        set DOCKER_NO_PROXY=%~2
        shift
    ) else (
        call :PrintError "Invalid command %1"
        call :Usage
        exit /b 1
    ) 
    shift
    goto ParseArguments
:EndParseArguments


echo MACHINE_PATH=%MACHINE_PATH%
echo DOCKER_HOST=%DOCKER_HOST%
echo TAR_NAME=%TAR_NAME%
echo CONTAINER_NAME=%CONTAINER_NAME%
echo ARCHITECTURE=%ARCHITECTURE%
echo DOCKER_FTP_PROXY=%DOCKER_FTP_PROXY%
echo DOCKER_HTTP_PROXY=%DOCKER_HTTP_PROXY%
echo DOCKER_HTTPS_PROXY=%DOCKER_HTTPS_PROXY%
echo DOCKER_NO_PROXY=%DOCKER_NO_PROXY%


:ValidateEnvironment
    echo.
    echo Validating environment ...

    if not defined MACHINE_PATH (
        call :PrintError "Predix Machine path required"
        call :Usage
        exit /b 1
    )

    if not exist "%MACHINE_PATH%" (
        call :PrintError "Predix Machine location %MACHINE_PATH% not found"
        exit /b 1
    )

    where docker >nul 2>nul
    if !errorlevel!==1 (
        call :PrintError "Docker not found"
        exit /b 1
    )

    echo Environment OK 
:EndValidateEnvironment


:DockerizeMachine
    
    rem Setup variables
    set DOCKER_FOLDER=docker
    for %%f in ("%MACHINE_PATH%") do set MACHINE_FOLDER=%%~nxf
    set DOCKER_IMAGE_NAME=%DOCKER_IMAGE_PREFIX%-%ARCHITECTURE%:%MACHINE_BUILD_VERSION%-%CONTAINER_NAME%
    set DOCKER_FILE_NAME=%DOCKER_FILE_PREFIX%-%ARCHITECTURE%
    if defined TAR_NAME (
        set TAR_FILE=%TAR_NAME%-%CONTAINER_NAME%-%ARCHITECTURE%-%MACHINE_BUILD_VERSION%.tar
    ) else (
        set TAR_FILE=%MACHINE_FOLDER%-%ARCHITECTURE%.tar
    )   

    rem Remove old folder if exists
    cd "%SCRIPT_DIR%"
    rmdir /q /s "%DOCKER_FOLDER%\%MACHINE_FOLDER%" >nul 2>nul

    rem Copy Predix Machine to docker folder, removing features not supported in dockerized Predix Machine
    cd "%MACHINE_PATH%"
    cd ..
    echo \utilities\ > excludeList.txt
    echo \mbsa\ >> excludeList.txt
    echo \yeti\ >> excludeList.txt
    echo \bin\service_installation\ >> excludeList.txt
    xcopy /q /i /s /y ".\%MACHINE_FOLDER%" ".\%MACHINE_FOLDER%.temp" /exclude:excludeList.txt
    move ".\%MACHINE_FOLDER%.temp" "%SCRIPT_DIR%\%DOCKER_FOLDER%\%MACHINE_FOLDER%"
    del excludeList.txt
    cd  "%SCRIPT_DIR%\%DOCKER_FOLDER%"

    rem Setup Docker Client env
    if defined DOCKER_HOST (
        FOR /f "tokens=*" %%i IN ('docker-machine env --no-proxy "%DOCKER_HOST%"') DO %%i
    )
  
    rem Construct build command
    set COMMAND=docker build -f "%DOCKER_FILE_NAME%" -t "%DOCKER_IMAGE_NAME%"
    if defined DOCKER_FTP_PROXY (
        set COMMAND=%COMMAND% --build-arg ftp_proxy=%DOCKER_FTP_PROXY%
    )
    if defined DOCKER_HTTP_PROXY (
        set COMMAND=%COMMAND% --build-arg http_proxy=%DOCKER_HTTP_PROXY%
    )
    if defined DOCKER_HTTPS_PROXY (
        set COMMAND=%COMMAND% --build-arg https_proxy=%DOCKER_HTTPS_PROXY%
    )
    if defined DOCKER_NO_PROXY (
        set COMMAND=%COMMAND% --build-arg no_proxy=%DOCKER_NO_PROXY%
    )
    set COMMAND=%COMMAND% --build-arg MACHINE_DIR="%MACHINE_FOLDER%"

    set COMMAND=%COMMAND% .
    rem echo Calling command: %COMMAND%

    rem Build Docker image
    echo.
    echo Building Docker image ...
    call %COMMAND%
    if %errorlevel% neq 0 (
        echo docker build command failed: %COMMAND%
        echo Exiting.
        exit 1
    )

    rem Save and compress Docker image into file
    echo.
    echo Saving Docker image ...
    docker save -o "..\%TAR_FILE%" "%DOCKER_IMAGE_NAME%"
    if not exist "..\%TAR_FILE%" (
        call :PrintError "Generate Docker image failed"
        cd ..
        exit /b 1
    )
    rem jar -cMf ..\%TAR_FILE%.zip ..\%TAR_FILE%

    rem Remove temp folder
    rmdir /s /q "%MACHINE_FOLDER%"

    rem Return to original directory
    cd "%ORIGINAL_DIR%"


    rem Output status
    echo Created Docker image %TAR_FILE%
    goto :EOF
:EndDockerizeMachine


:PrintError
    echo.
    echo ####################  E R R O R ######################
    echo %~1
    echo ######################################################
    goto :EOF
 
:Usage
    echo.
    echo NAME:
    echo    DockerizeContainer - Create a Docker image for the specified Predix Machine container
    echo.
    echo USAGE:
    echo    DockerizeContainer [OPTIONS]
    echo.
    echo EXAMPLES:
    echo    DockerizeContainer -m c:\MyPredixMachine
    echo    DockerizeContainer -m c:\MyPredixMachine --docker_host default --arch x86_64 --container_name agent --tar_name PredixMachine --http_proxy http://proxy-src.research.ge.com:8080 --https_proxy http://proxy-src.research.ge.com:8080 --no_proxy "localhost,127.0.0.1,*.ge.com"
    echo. 
    echo REQUIRED:
    echo    -m ^<MACHINE_PATH^>                    Path of Predix Machine for which the Docker image is created 
    echo.
    echo OPTIONS:    
    echo    --docker_host ^<DOCKER_HOST^>          Name of Docker host to use, for example 'default'
    echo    --tar_name ^<TAR_NAME^>                Base name of the tar resulting file
    echo    --container_name ^<CONTAINER_NAME^>    Meaningful name reflective of the predix machine container. e.g 'provision' for the provisioning container. It forms part of the docker image tag. Defaults to 'default'
    echo    --arch ^<ARCHITECTURE^>                Target architecture of the docker image. Default to 'x86_64'
    echo.
    echo OPTIONAL DOCKER BUILD ARGUMENTS: 
    echo    --ftp_proxy ^<FTP_PROXY_SERVER^>       FTP proxy server setting for Dockerized Predix Machine
    echo    --http_proxy ^<PROXY_SERVER^>          HTTP proxy server setting for Dockerized Predix Machine
    echo    --https_proxy ^<PROXY_SERVER^>         HTTPS proxy server setting for Dockerized Predix Machine
    echo    --no_proxy ^<PROXY_EXCEPTIONS^>        A set of comma-separated domains that do not go through the proxy
    echo.
    goto :EOF