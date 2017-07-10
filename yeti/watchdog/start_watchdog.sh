#!/bin/sh
# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied

DIRNAME=`dirname "$0"`
PREDIX_MACHINE_HOME=`cd "$DIRNAME/../.."; pwd`
PREDIX_MACHINE_DATA=${PREDIX_MACHINE_DATA_DIR-$PREDIX_MACHINE_HOME}
START_PREDIX_MACHINE_LOG=$PREDIX_MACHINE_DATA/logs/machine/start_predixmachine.log

# This function takes a string value, creates a timestamp, and writes it the log file as well as the console
writeConsoleLog () {
    echo "$(date +"%m/%d/%y %H:%M:%S") $1"
    if [ "x$START_PREDIX_MACHINE_LOG" != "x" ]; then
       echo "$(date +"%m/%d/%y %H:%M:%S") $1" >> "$START_PREDIX_MACHINE_LOG"
    fi
}

# Sets the watchdog environmental variable that is passed to the Java process.  This is used
# by the framework to indicate if the framework will be restarted if shutdown.
PREDIX_MACHINE_WATCHDOG=started
export PREDIX_MACHINE_WATCHDOG

START_CONTAINER=$PREDIX_MACHINE_HOME/machine/bin/predix/start_container.sh

# Check the environment for the PREDIXMACHINELOCK variable.  If not set use the security directory.
if [ ! -n "${PREDIXMACHINELOCK+1}" ]; then
    PREDIXMACHINELOCK=$PREDIX_MACHINE_DATA/security
fi

# The stop signal is used to indicate the watchdog loop should exit.
WATCHDOG_STOP_SIGNAL=$PREDIXMACHINELOCK/stop_watchdog
if [ -e /dev/fd/8 ]; then
    exec 1>&8 8>&-
fi
if [ -e /dev/fd/9 ]; then
    exec 2>&9 9>&-
fi
# Restart loop to keep the container running as long as the WATCHDOG_STOP_SIGNAL doesn't exist
while [ ! -f "$WATCHDOG_STOP_SIGNAL" ]; do
	writeConsoleLog "Watchdog starting framework..."
	sh "$START_CONTAINER"
	writeConsoleLog "Framework was shutdown."
    sleep 5
done

rm "$WATCHDOG_STOP_SIGNAL"