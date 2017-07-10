#!/bin/sh

# Copyright (c) 2012-2016 General Electric Company. All rights reserved."
# The copyright to the computer software herein is the property of"
# General Electric Company. The software may be used and/or copied only"
# with the written permission of General Electric Company or in accordance"
# with the terms and conditions stipulated in the agreement/contract"
# under which the software has been supplied"


# Copies oppdata, configuration, logs and system folders from inside a virgin Predix Machine container to the
# directory specified by the environment variable PREDIX_MACHINE_DATA_DIR if set.

# /PredixMachine is set by dockerfile statically
PredixMachineDir=/PredixMachine

# Check that the environment variable is set
[ -z ${PREDIX_MACHINE_DATA_DIR} ] &&
{
	echo PREDIX_MACHINE_DATA_DIR is not set. Setting to /data. ;
	export PREDIX_MACHINE_DATA_DIR=/data
}

# Check that the docker enabled environment variable is set
[ -z ${PREDIX_MACHINE_DOCKER_ENABLED} ] &&
{
	echo PREDIX_MACHINE_DOCKER_ENABLED is not set. Setting to true. ;
	export PREDIX_MACHINE_DOCKER_ENABLED=true
}

# Check that the directory specified by the environment variable exists and is writable
[ ! -d ${PREDIX_MACHINE_DATA_DIR} -o ! -w ${PREDIX_MACHINE_DATA_DIR} ] &&
{
	echo Failed. Directory $PREDIX_MACHINE_DATA_DIR does not exist, perhaps because no volume is provided.;
	exit 1;
}

# Check that the destination directory specified by PREDIX_MACHINE_DATA_DIR does not already contain the said folders (which should not be overwritten)
[ ! -d ${PREDIX_MACHINE_DATA_DIR}/appdata -a ! -d ${PREDIX_MACHINE_DATA_DIR}/configuration -a ! -d ${PREDIX_MACHINE_DATA_DIR}/logs -a ! -d ${PREDIX_MACHINE_DATA_DIR}/security -a ! -d ${PREDIX_MACHINE_DATA_DIR}/installations ] &&
{
	echo ${PREDIX_MACHINE_DATA_DIR} directory does not contain Predix Machine folders. Moving them there.;

	#check that the Predix Machine root dir exists, is readable, and contains the appdata, configuration, logs, security and installations folders
	[ ! -d ${PredixMachineDir} -o ! -r ${PredixMachineDir} ] ||
	[ ! -d ${PredixMachineDir}/appdata -o ! -r ${PredixMachineDir}/appdata ] ||
	[ ! -d ${PredixMachineDir}/configuration -o ! -r ${PredixMachineDir}/configuration ] ||
	[ ! -d ${PredixMachineDir}/logs -o ! -r ${PredixMachineDir}/logs ] ||
	[ ! -d ${PredixMachineDir}/security -o ! -r ${PredixMachineDir}/security ] &&
	{
		echo Failed. $1 is not a well formed Predix Machine root directory or contents are not accessible.;
		exit 1;
	}

	# Move the Predix Machine directories into the directory specified by PREDIX_MACHINE_DATA_DIR
	mv ${PredixMachineDir}/appdata 			${PREDIX_MACHINE_DATA_DIR}
	mv ${PredixMachineDir}/configuration 	${PREDIX_MACHINE_DATA_DIR}
	mv ${PredixMachineDir}/logs 			${PREDIX_MACHINE_DATA_DIR}
	mv ${PredixMachineDir}/security 		${PREDIX_MACHINE_DATA_DIR}

	# the installations directory is absent in some containers
	[ -d ${PredixMachineDir}/installations ] && { mv ${PredixMachineDir}/installations 	${PREDIX_MACHINE_DATA_DIR}; }
}

# If the folders in /data exists, delete the ones in the container. This is what happens when an upgrade
# container is installed. The upgrade brings its own appdata, configuration, logs and security folders.
rm -rf ${PredixMachineDir}/appdata
rm -rf ${PredixMachineDir}/configuration
rm -rf ${PredixMachineDir}/logs
rm -rf ${PredixMachineDir}/security
rm -rf ${PredixMachineDir}/installations

if [ ! -n "${PREDIXMACHINELOCK+1}" ]; then
	PREDIXMACHINELOCK=$PREDIX_MACHINE_DATA/security
fi

rm -f "$PREDIXMACHINELOCK/lock"

echo Starting Predix Machine...
/bin/sh -c "${PredixMachineDir}/bin/start_predixmachine.sh"