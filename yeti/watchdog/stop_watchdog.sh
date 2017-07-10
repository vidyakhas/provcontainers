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

# Check the environment for the PREDIXMACHINELOCK variable.  If not set use the security directory.
if [ ! -n "${PREDIXMACHINELOCK+1}" ]; then
    PREDIXMACHINELOCK=$PREDIX_MACHINE_DATA/security
fi

# The stop signal is used to indicate the Yeti loop should exit.
WATCHDOG_STOP_SIGNAL=$PREDIXMACHINELOCK/stop_watchdog
echo $$ > "$WATCHDOG_STOP_SIGNAL"
sh "$PREDIX_MACHINE_HOME/machine/bin/predix/stop_container.sh"

SHUTDOWNCHECKCNT=1
while true; do
	if [ "$SHUTDOWNCHECKCNT" -ge 180 ]; then
		writeConsoleLog "Error: Shutdown took longer than 3 minutes."
		exit 1
	# The start_watchdog script will remove the stop signal when it completes
	elif [ -f "$WATCHDOG_STOP_SIGNAL" ]; then
		sleep 1
		SHUTDOWNCHECKCNT=$((SHUTDOWNCHECKCNT+1))
	else
		writeConsoleLog "Watchdog has shutdown."
		exit 0
	fi
done