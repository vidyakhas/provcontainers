#!/bin/bash

# Copyright (c) 2012-2016 General Electric Company. All rights reserved."
# The copyright to the computer software herein is the property of"
# General Electric Company. The software may be used and/or copied only"
# with the written permission of General Electric Company or in accordance"
# with the terms and conditions stipulated in the agreement/contract"
# under which the software has been supplied"


# Constants 
readonly MACHINE_BUILD_VERSION=17.1.0
readonly DOCKER_FILE_PREFIX=Dockerfile-predixdtr-alpine
# DO NOT CHANGE THE VALUE OF THIS VARIABLE. IT TAGS PREDIX MACHINE WITH THIS NAME. THE BOOTSTRAP REQUIRES THIS.
readonly DOCKER_IMAGE_PREFIX=predixmachine


# Input Parameters & Defaults
MACHINE_PATH=
DOCKER_HOST=
TAR_NAME=
CONTAINER_NAME='default'
ARCHITECTURE=x86_64
DOCKER_FTP_PROXY=
DOCKER_HTTP_PROXY=
DOCKER_HTTPS_PROXY=
DOCKER_NO_PROXY=
JRE=jre7


# Print usage instructions
PrintUsage () {
    echo ""
    echo "NAME:"
    echo "   DockerizeContainer - Create a Docker image for the specified Predix Machine"
    echo ""
    echo "USAGE:"
    echo "   DockerizeContainer [OPTIONS]"
    echo ""
    echo "EXAMPLES:"
    echo "   ./DockerizeContainer.sh -m ~/MyPredixMachine"
    echo "   ./DockerizeContainer.sh -m ../ --docker_host default --arch x86_64 --container_name agent --tar_name PredixMachine --jre jre7 --http_proxy http://proxy-src.research.ge.com:8080 --https_proxy http://proxy-src.research.ge.com:8080 --no_proxy \"localhost,127.0.0.1,*.ge.com\""
    echo ""
    echo "REQUIRED:"
    echo "   -m <MACHINE_PATH>                          Path of Predix Machine for which the Docker image is created"
    echo ""
    echo "OPTIONS:"    
    echo "   --docker_host <DOCKER_HOST>                Name of Docker host to use, for example 'default'"
    echo "   --tar_name <TAR_NAME>                      Base name of the tar resulting file"
    echo "   --container_name <CONTAINER_NAME>          Meaningful name reflective of the Predix Machine container. e.g 'provision' for the provisioning container. It forms part of the docker image tag. Defaults to 'default'"
    echo "   --arch <ARCHITECTURE>                      Target architecture of the docker image. Defaults to 'x86_64'"
	echo "   --jre <JRE>                                The JRE to use in the image. Choices are jre7 (default) and jre8"
    echo ""
    echo "OPTIONAL DOCKER BUILD ARGUMENTS:"
    echo "   --ftp_proxy <FTP_PROXY_SERVER>             FTP proxy server setting for Dockerized Predix Machine"
    echo "   --http_proxy <PROXY_SERVER>                HTTP proxy server setting for Dockerized Predix Machine"
    echo "   --https_proxy <PROXY_SERVER>               HTTPS proxy server setting for Dockerized Predix Machine"
    echo "   --no_proxy <PROXY_EXCEPTIONS>              A set of comma-separated domains that do not go through the proxy"
    echo ""    
}

# Print error message and exit with status 1
PrintError () {
    echo ""
    echo "####################  E R R O R ######################"
    echo "$1"
    echo "######################################################"
}

# Init environment
InitEnvironment () {
    echo ""
    echo "Init environment ..."
    ORIGINAL_DIR=`pwd`
    echo ORIGINAL_DIR=$ORIGINAL_DIR

    SCRIPT_DIR=`echo $(cd $(dirname $0); pwd)`
    echo SCRIPT_DIR=$SCRIPT_DIR
}


# Parse input arguments and set globals
ParseArguments () {
    echo ""
    echo "Parsing arguments ..."
    while [[ $# -gt 0 ]]; do   
        case $1 in
            -h | -help | --help | -usage | ?)
                PrintUsage
                exit
                ;;
            -m | --machine)
                shift
                MACHINE_PATH=`echo $(cd $1; pwd)`
                echo MACHINE_PATH=$MACHINE_PATH
                ;;
            --docker_host)
                shift
                DOCKER_HOST="$1"
                echo DOCKER_HOST=$DOCKER_HOST
                ;;    
            --container_name)
                shift
                CONTAINER_NAME="$1"
                echo CONTAINER_NAME=$CONTAINER_NAME
                ;;    
            --arch)
                shift
                ARCHITECTURE="$1"
                echo ARCHITECTURE=$ARCHITECTURE
                ;;
            --tar_name)
                shift
                TAR_NAME="$1"
                echo TAR_NAME=$TAR_NAME
                ;;
            --jre)
                shift
                JRE="$1"
                echo JRE=$JRE
                ;;
            --ftp_proxy)
                shift
                DOCKER_FTP_PROXY="$1"
                echo DOCKER_FTP_PROXY=$DOCKER_FTP_PROXY
                ;;    
            --http_proxy)
                shift
                DOCKER_HTTP_PROXY="$1"
                echo DOCKER_HTTP_PROXY=$DOCKER_HTTP_PROXY
                ;;
            --https_proxy)
                shift
                DOCKER_HTTPS_PROXY="$1"
                echo DOCKER_HTTPS_PROXY=$DOCKER_HTTPS_PROXY
                ;;
            --no_proxy)
                shift
                DOCKER_NO_PROXY="$1"
                echo DOCKER_NO_PROXY=$DOCKER_NO_PROXY
                ;;
            *)
                PrintError "Invalid command $1"
                PrintUsage
                exit 1
        esac
        shift
    done
}

# Validate environment before generation
ValidateEnvironment () {

    echo ""
    echo "Validating environment ..."

    if [ -z "$MACHINE_PATH" ]; then
        PrintError "Predix Machine path required"
        PrintUsage
        exit 1
    fi
    
    if [ ! -e "$MACHINE_PATH" ]; then 
        PrintError "Predix Machine "$MACHINE_PATH" not found"
        exit 1
    fi
    
    command -v "docker" >/dev/null 2>&1 || {
        PrintError "Docker not found";
        exit 1;
    }

    echo "Environment OK"
}

# Convert generated Predix Machine into Docker image and save image into compressed file
DockerizeMachine () {

    # Setup variables
    DOCKER_FOLDER=docker
    MACHINE_FOLDER=$(basename "$MACHINE_PATH")
    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_PREFIX}-${ARCHITECTURE}:${MACHINE_BUILD_VERSION}-${CONTAINER_NAME}
    DOCKER_FILE_NAME=${DOCKER_FILE_PREFIX}-${ARCHITECTURE}-${JRE}
    if [ ! -z "$TAR_NAME" ]; then
        TAR_FILE=${TAR_NAME}-${CONTAINER_NAME}-${ARCHITECTURE}-${JRE}-${MACHINE_BUILD_VERSION}.tar
    else
        TAR_FILE=${MACHINE_FOLDER}-${ARCHITECTURE}-${JRE}.tar
    fi

    # Remove old folder if exists
    cd "$SCRIPT_DIR"
    rm -rf "./$DOCKER_FOLDER/$MACHINE_FOLDER"

    # Copy Predix Machine to docker folder
    SCRIPT_DIR=`pwd`
    cd "$MACHINE_PATH"
    cd ..
    tar -cf - --exclude 'utilities' --exclude 'mbsa' --exclude 'yeti' --exclude 'bin/service_installation' "./$MACHINE_FOLDER" | ( cd "$SCRIPT_DIR/$DOCKER_FOLDER" && tar xpf - )
    cd "$SCRIPT_DIR/$DOCKER_FOLDER"

    # Setup Docker Client env
    if [ ! -z "$DOCKER_HOST" ]; then
        eval $(docker-machine env --no-proxy "$DOCKER_HOST")
    fi

    # Construct build command
    COMMAND="docker build -f \"${DOCKER_FILE_NAME}\" -t \"${DOCKER_IMAGE_NAME}\""
    if [ ! -z "$DOCKER_FTP_PROXY" ]; then
        COMMAND+=" --build-arg ftp_proxy=$DOCKER_FTP_PROXY"
    fi
    if [ ! -z "$DOCKER_HTTP_PROXY" ]; then
        COMMAND+=" --build-arg http_proxy=$DOCKER_HTTP_PROXY"
    fi
    if [ ! -z "$DOCKER_HTTPS_PROXY" ]; then
        COMMAND+=" --build-arg https_proxy=$DOCKER_HTTPS_PROXY"
    fi
    if [ ! -z "$DOCKER_NO_PROXY" ]; then
        COMMAND+=" --build-arg no_proxy=$DOCKER_NO_PROXY"
    fi
    COMMAND+=" --build-arg MACHINE_DIR=\"$MACHINE_FOLDER\""
    COMMAND+=" ."

    # Build Docker image
    echo ""
    echo "Building Docker image ..."
    eval $COMMAND
    [ $? -ne 0 ] && {
        echo \'docker build\' command failed: $COMMAND
        echo Exiting.
        exit 1
    }

    # Save and compress Docker image to file
    echo ""
    echo "Saving Docker image ..."
    docker save -o ../"$TAR_FILE" "${DOCKER_IMAGE_NAME}"
    if [ ! -e ../"$TAR_FILE" ]; then
        PrintError "Generate Docker image failed"
        cd ..
        exit 1
    fi
    gzip -f ../"$TAR_FILE"
    
    # Remove temp folder
    rm -rf "$MACHINE_FOLDER"

    # Return to original directory
    cd "$ORIGINAL_DIR" 
    
    # Output status
    echo "Created Docker image ${TAR_FILE}.gz"
}


##################################################
# main()
##################################################

InitEnvironment
ParseArguments $@
ValidateEnvironment
DockerizeMachine