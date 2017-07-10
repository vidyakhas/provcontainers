#!/bin/sh
# Copyright (c) 2012-2017 General Electric Company. All rights reserved.
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
# The second argument is the path to the migration directory.  This contains
# the new 17.1 files to be installed.
# The third argument is the name of the zip.  This must be used to create
# the JSON file to verify the status of the installation.  The JSON must be
# placed in the appdata/packageframework directory with the name $ZIPNAME.json

# Upgrading Yeti proceeds as follows:
# 1. Fix any permissions on scripts as they may have changed in the zipping process
# 2. Copy the new Yeti into place
# 3. Copy the new Yeti config into place
# 4. Restart the predixmachine service

# Set the variables used in the script
PREDIX_MACHINE_DATA=$1
UPDATEDIR=$2
ZIPNAME=$3
DATE=`date +%m%d%y%H%M%S`
PACKAGEFRAMEWORK=${PREDIX_MACHINE_DATA}/appdata/packageframework
# All output from this file is redirected to a log file in logs/installations/packagename-x.x.x using file descriptor 8 and 9

status="failure"
errorcode="1"
message="Migration failed unexpectedly."

# Write to the log file with the date
writeConsoleLog () {
	echo "$(date +"%m/%d/%y %H:%M:%S") $1"
}

# Called in any failure. Restarts the container and exits with the errorcode
rollback () {
	trap - EXIT
	echo "Update unsuccessful. Attempting to rollback."
	restoreOld "yeti"
	sleep 10
	start_container
	exit $errorcode
}

# Restore all the old backed up directories to a state
restoreOld () {
	directory=${PREDIX_MACHINE_DATA}/$1
	if [ -d "$directory.old" ]; then
		rm -v -r "$directory/"
		mv -v "$directory.old/" "$directory/"
		if [ $? -eq 0 ]; then
			echo "Rollback of $directory successful."
		else
			echo "Rollback of $directory unsuccessful."
		fi
	fi
}

# Restart the systemd service after installation for yeti changes to take effect
restart_pm_service () {
	echo "################################### RESTARTING SERVICE IN 2 MINUTES ###################################"
	sh "${PREDIX_MACHINE_DATA}/yeti/install/reload.sh" &
}

# Look for the cloud connection message in the logs
finish () {
	echo "$message"
	printf "{\n\t\"status\" : \"$status\",\n\t\"message\" : \"$message\",\n\t\"starttime\" : $starttime,\n\t\"endtime\" : $(date +%s)\n}\n" > "$PACKAGEFRAMEWORK/$ZIPNAME.json"
	# Remove the exit trap at this point, container is started and is removing the rolled back directories
	trap - EXIT
	restart_pm_service
}

# Backup the directory given by the argument and replace it with the new directory from the update
backupDirAndReplace() {
	backupDir $1
	mv -v "$UPDATEDIR/$application/" "${PREDIX_MACHINE_DATA}/$application/"
	if [ $? -ne 0 ]; then
		message="The $application application could not be updated."
		errorcode="56"
		status="failure"
		exit
	else
		message="The $application application has been updated."
		errorcode="0"
		status="success"
	fi
}

# Rename the backup of the directory given to .old
backupDir() {
	application=$1
	# Cleanup any folders from a previous install
	rm -rv "${PREDIX_MACHINE_DATA}/$application.old"

	echo "Backing up the $application directory."
	mv -v "${PREDIX_MACHINE_DATA}/$application/" "${PREDIX_MACHINE_DATA}/$application.old/"
	if [ $? -eq 0 ]; then
		echo "The $application application backup created as $application.old."
	else
		message="The $application application could not be renamed to $application.old."
		errorcode="55"
		status="failure"
		exit
	fi
}

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

# The script starts here
echo "Starting Yeti upgrade."
starttime=$(date +%s)
DATE=`date +%m%d%y%H%M%S`
# If scripts exits for any reason from this point, rollback any changes.
trap rollback EXIT
fixFilePermissions
backupDirAndReplace "yeti"
finish
echo "Yeti upgrade successful."
exit 0