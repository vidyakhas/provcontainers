#!/bin/sh
# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied.

cd "$(dirname "$0")/../../.."
PREDIX_MACHINE_HOME=$(pwd)
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

if [ ! -f "$PREDIXMACHINELOCK/lock" ]; then
	writeConsoleLog "Lock file doesn't exist. Predix Machine is not running."
	exit 1
fi
# Try to shutdown by grabbing the process id. Will only work on shells with ps ax capability.
ps ax > /dev/null
if [ $? -eq 0 ]; then
	writeConsoleLog "Terminating Predix Machine process."
	pmpid=$(ps ax | grep com.prosyst.mbs.impl.framework.Start | grep -v grep | awk '{print $1}')
	if [ "x$pmpid" != "x" ]; then
		for pmprcs in $pmpid; do
			kill -TERM $pmprcs
		done
	else
		writeConsoleLog "Predix Machine process was not found to be running. Removing lock file."
		rm "$PREDIXMACHINELOCK/lock"
	fi
else
# If it doesn't have ps aux use the shutdown hook, will spawn another JVM
	SHUTDOWNCHECKCNT=1
	while true; do
		if [ "$SHUTDOWNCHECKCNT" -ge 60 ]; then
			writeConsoleLog "Error: Could not initiate connection with shutdown hook server."
			break
		fi
		# The secretkey_keystore is created on startup of the framework for the first time
		if [ ! -f "$PREDIX_MACHINE_DATA/security/secretkey_keystore.jceks" ]; then
			writeConsoleLog "Framework has not started yet."
			sleep 3
			SHUTDOWNCHECKCNT=$((SHUTDOWNCHECKCNT+1))
			continue
		fi
		# Calling the shutdown hook client jar sends a shutdown signal to the framework
		java -cp "$PREDIX_MACHINE_DATA"/machine/bundles/com.ge.dspmicro.securityadmin-17.1.0.jar:"$PREDIX_MACHINE_DATA"/machine/bin/predix/com.ge.dspmicro.shutdown-hook-client-17.1.0.jar com.ge.dspmicro.shutdownhookclient.ShutdownHookClient
		# The process will return a 0 if the signal was sent successfully
		if [ $? -ne 0 ]; then
			writeConsoleLog "Attempting to contact the shutdown hook server..."
			sleep 3
			SHUTDOWNCHECKCNT=$((SHUTDOWNCHECKCNT+1))
		else
			writeConsoleLog "Shutdown signal sent successfully."
			break
		fi
	done
fi

SHUTDOWNCHECKCNT=1
while true; do
	if [ "$SHUTDOWNCHECKCNT" -ge 180 ]; then
		writeConsoleLog "Error: Framework shutdown took longer than 3 minutes."
		exit 1
	# The start_container script will remove the lock file when it completes
	elif [ -f "$PREDIXMACHINELOCK/lock" ]; then
		sleep 1
		SHUTDOWNCHECKCNT=$((SHUTDOWNCHECKCNT+1))
	else
		writeConsoleLog "Framework has shutdown."
		exit 0
	fi
done