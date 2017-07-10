#!/bin/sh

# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied

writeConsoleLog () {
    echo "$(date +"%m/%d/%y %H:%M:%S") $1"
    if [ "x$START_PREDIX_MACHINE_LOG" != "x" ]; then
       echo "$(date +"%m/%d/%y %H:%M:%S") $1" >> "$START_PREDIX_MACHINE_LOG"
    fi
}

DIRNAME=`dirname "$0"`
PREDIX_MACHINE_HOME=`cd "$DIRNAME/../../.."; pwd`
PREDIX_MACHINE_DATA=${PREDIX_MACHINE_DATA_DIR-$PREDIX_MACHINE_HOME}
START_PREDIX_MACHINE_LOG=$PREDIX_MACHINE_DATA/logs/machine/start_predixmachine.log

# Some Linux systems have been known to have Java in the path, but not keytool,
# which may be accessible via $JAVA_HOME. This function adds $JAVA_HOME/bin to path 
# if indeed keytool is not in path but is under $JAVA_HOME.
locate_keytool()
{
    command -v keytool >/dev/null 2>&1  &&  {   
        return 0;  
    }   
    
    command -v ${JAVA_HOME}/bin/keytool >/dev/null 2>&1  && { 
        export PATH=$PATH:${JAVA_HOME}/bin
        return 0;  
    }   
    return 1;
}

# Exit if keytool is not installed.
if ! locate_keytool; then
	writeConsoleLog "Java keytool not found.  Exiting."
	exit 1
fi

# Exit if lock file exists
if [ ! -n "${PREDIXMACHINELOCK+1}" ]; then
    PREDIXMACHINELOCK=$PREDIX_MACHINE_HOME/security
fi

if [ -f "$PREDIXMACHINELOCK/lock" ]; then
    writeConsoleLog "Predix Machine lock file exists at $PREDIXMACHINELOCK/lock.  Either another instance of Predix Machine is running, or the last instance was shutdown incorrectly."
    exit 1
fi