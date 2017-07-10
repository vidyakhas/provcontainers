#!/bin/sh
# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied.

usage()
{
cat << EOF
usage: $0 options

Start script for predix machine

OPTIONS:
   --force-root      Allow container to be run with elevated administrator privileges. Not recommended.
EOF
}

writeConsoleLog () {
    echo "$(date +"%m/%d/%y %H:%M:%S") $1"
    if [ "x$START_PREDIX_MACHINE_LOG" != "x" ]; then
       echo "$(date +"%m/%d/%y %H:%M:%S") $1" >> "$START_PREDIX_MACHINE_LOG"
    fi
}

START_ORIGIN="$(pwd)"
cd "$(dirname "$0")/.."
PREDIX_MACHINE_HOME=$(pwd)
PREDIX_MACHINE_DATA=${PREDIX_MACHINE_DATA_DIR-$PREDIX_MACHINE_HOME}
START_PREDIX_MACHINE_LOG=$PREDIX_MACHINE_DATA/logs/machine/start_predixmachine.log
echo > $START_PREDIX_MACHINE_LOG

root=false
while [ "$1" != "" ]; do
	case "$1" in
		--force-root )
				root=true
				;;
		?)
			usage
			exit 1
			;;
	esac
	shift
done

# Exit if user is running as root
if [ $(id -u) -eq 0 ]; then
    if [ "$root" = "false" ]; then
        writeConsoleLog "Predix Machine should not be run as root.  We recommend you create a low privileged \
predixmachineuser, allowing them only the required root privileges to execute machine.  Bypass \
this error message with the argument --force-root"
        exit 1
    fi
fi

if [ -f "./yeti/start_yeti.sh" ]; then
    sh "$PREDIX_MACHINE_HOME"/yeti/start_yeti.sh
elif [ -f "./machine/bin/predix/start_container.sh" ]; then
    sh "$PREDIX_MACHINE_HOME"/machine/bin/predix/start_container.sh
else
    writeConsoleLog "The directory structure was not recognized.  Predix Machine could not be started."
    cd "$START_ORIGIN"
    exit 1
fi

cd "$START_ORIGIN"