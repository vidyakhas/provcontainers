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

# This install script will be called by yeti which will provide three arguements
# The first argument is the Predix Home directory which is the directory to the
# Predix Machine container
# The second arguement is the path to the application directory.  This contains
# the new application to be installed.
# The third arguement is the name of the zip.  This must be used to create
# the JSON file to verify the status of the installation.  The JSON must be
# placed in the appdata/packageframework directory with the name $ZIPNAME.json

# Updating the application proceeds as follows:
# 1. Make a backup of previous application
# 2. Add new application
# 3. Return an error code or 0 for success
PREDIX_MACHINE_HOME=$1
UPDATEDIR=$2
ZIPNAME=$3
STARTED_BY_AGENT=$4

# Let Agent handle restarting Predix Machine if install script is started by Agent
echo "STARTED_BY_AGENT=$STARTED_BY_AGENT"

DATE=`date +%m%d%y%H%M%S`
# Replace this with the name of your application directory
application=machine
PACKAGEFRAMEWORK=$PREDIX_MACHINE_HOME/appdata/packageframework
# All output from this file is redirected to a log file in logs/installations/packagename-x.x.x using file descriptor 6


# Fix any permissions issues with the incoming scripts caused by the zipping process
fixFilePermissions () {
	# On some systems the tmp directory belongs to the wheel user group
	chown -R :"$(id -gn)" "$UPDATEDIR"
	writeConsoleLog "Fixing script permissions"
	for script in $(find "$UPDATEDIR" -type f -name "*.sh"); do
		writeConsoleLog "Fixing permissions on $script"
		chmod 744 "$script"
	done
}

# A trap method that's called on install completion.  Writes the status file
finish () {
	echo "$message"
	if [ $errorcode -eq 0 ]; then
		printf "{\n\t\"status\" : \"$status\",\n\t\"message\" : \"$message\",\n\t\"starttime\" : $starttime,\n\t\"endtime\" : $(date +%s)\n}\n" > "$PACKAGEFRAMEWORK/$ZIPNAME.json"
	else
		printf "{\n\t\"status\" : \"$status\",\n\t\"errorcode\" : $errorcode,\n\t\"message\" : \"$message\",\n\t\"starttime\" : $starttime,\n\t\"endtime\" : $(date +%s)\n}\n" > "$PACKAGEFRAMEWORK/$ZIPNAME.json"
	fi
	# Start the container before exiting
	if [ -f "$PREDIX_MACHINE_HOME/yeti/watchdog/start_watchdog.sh" ]; then
		sh "$PREDIX_MACHINE_HOME/yeti/watchdog/start_watchdog.sh" &
	elif [ -f "$PREDIX_MACHINE_HOME/mbsa/bin/mbsa_start.sh" ]; then
		sh "$PREDIX_MACHINE_HOME/mbsa/bin/mbsa_start.sh" &
	fi
	exit $errorcode
}
trap finish EXIT

rollback () {
	directory=$1
	echo "Update unsuccessful. Attempting to rollback."
	if [ -d "$PREDIX_MACHINE_HOME/$directory" ]; then
		rm -v -r "$PREDIX_MACHINE_HOME/$directory/"
	fi
	mv -v "$PREDIX_MACHINE_HOME/$directory.old/" "$PREDIX_MACHINE_HOME/$directory/"
	if [ $? -eq 0 ]; then
		echo "Rollback successful."
	else
		echo "Rollback unsuccessful."
	fi
}

# Performs the application install.  Uses the $application environmental variable set to determine the application to update
applicationInstall () {
	# Shutdown container for update
	echo "$(date +"%m/%d/%y %H:%M:%S") ##########################################################################"
	echo "$(date +"%m/%d/%y %H:%M:%S") #                 Shutting down container for update                     #"
	echo "$(date +"%m/%d/%y %H:%M:%S") ##########################################################################"

	if [ -f "$PREDIX_MACHINE_HOME/yeti/watchdog/stop_watchdog.sh" ]; then
		sh "$PREDIX_MACHINE_HOME/yeti/watchdog/stop_watchdog.sh"
	elif [ -f "$PREDIX_MACHINE_HOME/mbsa/bin/mbsa_stop.sh" ]; then
		sh "$PREDIX_MACHINE_HOME/mbsa/bin/mbsa_stop.sh"
    elif [ $STARTED_BY_AGENT == "true" ]; then
        echo "Container restart will be handled by Predix Machine Agent."
	else
		message="Unable to find a valid shutdown method for the Predix Machine framework. Install failed"
		errorcode="52"
		status="failure"
		exit
	fi

	echo "Updating the $application directory."
	if [ -d "$PREDIX_MACHINE_HOME/$application" ]; then
		echo "Updating $application application. Backup of current application stored in $application.old."
		if [ -d "$PREDIX_MACHINE_HOME/$application.old" ]; then
			echo "Updating $application.old application backup to revision before this update."
			rm -v -r "$PREDIX_MACHINE_HOME/$application.old/"
			if [ $? -eq 0 ]; then
				echo "Previous $application.old removed."
			else
				message="Previous $application.old could not be removed."
				errorcode="54"
				status="failure"
				exit
			fi
		fi
		mv -v "$PREDIX_MACHINE_HOME/$application/" "$PREDIX_MACHINE_HOME/$application.old/"
		if [ $? -eq 0 ]; then
			echo "The $application application backup created as $application.old."
		else
			message="The $application application could not be renamed to $application.old."
			errorcode="55"
			status="failure"
			exit
		fi
	fi
	mv -v "$UPDATEDIR/$application/" "$PREDIX_MACHINE_HOME/$application/"

	if [ $? -eq 0 ]; then
		chmod +x "$PREDIX_MACHINE_HOME/$application/bin/predix/start_container.sh"
		chmod +x "$PREDIX_MACHINE_HOME/$application/bin/predix/stop_container.sh"

		message="The $application application was updated successfully."
		errorcode="0"
		status="success"
		exit
	else
		message="The $application application could not be updated."
		errorcode="56"
		status="failure"
		# Attempt a rollback
		rollback "$application"
		exit
	fi
}

# Update the $application application by removing any old backups, renaming the
# current installed application to $application.old, and adding the updated
# application
fixFilePermissions
applicationInstall