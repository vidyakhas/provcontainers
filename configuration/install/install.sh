#!/bin/sh
# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied.

# This is the status that will be written if the script exits unexpectedly
starttime=$(date +%s)
status="failure"
errorcode="51"
message="Installation failed unexpectedly."

# This install script will be called by yeti which will provide three arguments
# The first argument is the Predix Home directory which is the directory to the 
# Predix Machine container
# The second argument is the path to the configuration directory.  This contains 
# the new configuration application to be installed.
# The third argument is the name of the zip.  This must be used to create
# the JSON file to verify the status of the installation.  The JSON must be
# placed in the appdata/packageframework directory with the name $ZIPNAME.json

# Files can be added to the whitelist so they are not overwritten.  These could 
# include configurations that contain encoded passwords or parameters generated
# by the container on startup.

# Updating the configuration proceeds as follows:
# 1. Make a backup of previous configuration
# 2. Overlay configuration files found in the directory if they are not in the whitelist
# 3. Return an error code or 0 for success

PREDIX_MACHINE_DATA=$1
UPDATEDIR=$2
ZIPNAME=$3
STARTED_BY_AGENT=$4

# Let Agent handle restarting Predix Machine if install script is started by Agent
echo "STARTED_BY_AGENT=$STARTED_BY_AGENT"

DATE=`date +%m%d%y%H%M%S`
PACKAGEFRAMEWORK=$PREDIX_MACHINE_DATA/appdata/packageframework
# All output from this file is redirected to a log file in logs/installations/packagename-x.x.x using file descriptor 6

finish () {
	echo "$message"
	if [ $errorcode -eq 0 ]; then
		printf "{\n\t\"status\" : \"$status\",\n\t\"message\" : \"$message\",\n\t\"starttime\" : $starttime,\n\t\"endtime\" : $(date +%s)\n}\n" > "$PACKAGEFRAMEWORK/$ZIPNAME.json"
	else
		printf "{\n\t\"status\" : \"$status\",\n\t\"errorcode\" : $errorcode,\n\t\"message\" : \"$message\",\n\t\"starttime\" : $starttime,\n\t\"endtime\" : $(date +%s)\n}\n" > "$PACKAGEFRAMEWORK/$ZIPNAME.json"
	fi
	# Start the container before exiting
	# Check for the start_watchdog.sh file.  This won't exist in a dockerized machine so we don't start up.
	if [ -f "$PREDIX_MACHINE_DATA/yeti/watchdog/start_watchdog.sh" ]; then
		sh "$PREDIX_MACHINE_DATA/yeti/watchdog/start_watchdog.sh" &
	elif [ -f "$PREDIX_MACHINE_DATA/mbsa/bin/mbsa_start.sh" ]; then
		sh "$PREDIX_MACHINE_DATA/mbsa/bin/mbsa_start.sh" &
	fi
	exit $errorcode
}
trap finish EXIT

rollback () {
	directory=$1
	echo "Update unsuccessful. Attempting to rollback."
	if [ -d "$PREDIX_MACHINE_DATA/$directory" ]; then
		rm -v -r "$PREDIX_MACHINE_DATA/$directory/"
	fi
	mv -v "$PREDIX_MACHINE_DATA/$directory.old/" "$PREDIX_MACHINE_DATA/$directory/"
	if [ $? -eq 0 ]; then
		echo "Rollback successful."
	else
		echo "Rollback unsuccessful."
	fi
}

configurationInstall () {
	# Shutdown container for update
	echo "$(date +"%m/%d/%y %H:%M:%S") ##########################################################################"
	echo "$(date +"%m/%d/%y %H:%M:%S") #                 Shutting down container for update                     #"
	echo "$(date +"%m/%d/%y %H:%M:%S") ##########################################################################"
	# Check for the stop_watchdog.sh file.  This won't exist in a dockerized machine so we don't shut down.
	if [ -f "$PREDIX_MACHINE_DATA/yeti/watchdog/stop_watchdog.sh" ]; then
		sh "$PREDIX_MACHINE_DATA/yeti/watchdog/stop_watchdog.sh"
	elif [ -f "$PREDIX_MACHINE_DATA/mbsa/bin/mbsa_stop.sh" ]; then
		sh "$PREDIX_MACHINE_DATA/mbsa/bin/mbsa_stop.sh"
	elif [ $STARTED_BY_AGENT == "true" ]; then
        echo "Container restart will be handled by Predix Machine Agent."
    else 
		message="Unable to find a valid shutdown method for the Predix Machine framework. Install failed"
		errorcode="52"
		status="failure"
		exit
	fi
	# Install the configurations
	
	# These configurations should not be overwritten
	#   com.ge.dspmicro.predixcloud.identity.config (client id and secret)
	#   com.ge.dspmicro.storeforward-*.config  (generated database password will never accessible again if you overwrite)
	#   com.ge.dspmicro.device.techconsole.config – This says if the technician console should be enabled. This should only be done through the the command and not through configuration overwrite.
	WHITELIST='com.ge.dspmicro.predixcloud.identity.config \
	com.ge.dspmicro.device.techconsole.config \
	org.apache.http.proxyconfigurator-0.config \
	com.ge.dspmicro.predix.connectivity.openvpn.config \
	com.ge.dspmicro.storeforward-taskstatus.config \
	com.ge.dspmicro.storeforward-0.config \
	com.ge.dspmicro.storeforward-1.config \
	com.ge.dspmicro.storeforward-2.config \
	com.ge.dspmicro.storeforward-3.config'

	echo "Updating the configuration directory."
	echo "Looking for whitelisted files in the installation package."
	for config in $WHITELIST; do
		configpath="$(find $UPDATEDIR -name "${config}")"
		for configpaths in $configpath; do
			relpath=${configpaths#${UPDATEDIR}}
			if [ -e "$PREDIX_MACHINE_DATA${relpath}" ]; then
				echo "Removing whitelisted file ${configpaths}"
				rm -v "${configpaths}"
			fi
		done
	done

	# Update the configuration by removing any old backups, renaming the
	# current installed to configuration.old, and adding the updated configuration

	if [ -d "$PREDIX_MACHINE_DATA/configuration" ]; then
		echo "Updating configuration. Backup of current stored in configuration.old"
		if [ -d "$PREDIX_MACHINE_DATA/configuration.old" ]; then
			echo "Updating configuration.old backup to revision before this update"
			rm -v -r "$PREDIX_MACHINE_DATA/configuration.old/"
			if [ $? -eq 0 ]; then
				echo "Previous configuration.old removed"
			else
				message="Previous configuration.old could not be removed."
				errorcode="54"
				status="failure"
				exit
			fi
		fi
		cp -v -Rp "$PREDIX_MACHINE_DATA/configuration/" "$PREDIX_MACHINE_DATA/configuration.old/"
		if [ $? -eq 0 ]; then
			echo "Configuration backup created as configuration.old"
		else
			message="Previous configuration directory could not be copied to configuration.old."
			errorcode="55"
			status="failure"
			exit
		fi
	fi
	cp -v -Rp "$UPDATEDIR/configuration"/* "$PREDIX_MACHINE_DATA/configuration"

	# Wrap up and create status json
	if [ $? -eq 0 ]; then
		message="The configuration was updated successfully."
		errorcode="0"
		status="success"
		exit
	else
		message="Configuration could not be updated."
		errorcode="56"
		status="failure"
		rollback "configuration"
		exit
	fi
}

configurationInstall