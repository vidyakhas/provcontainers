#!/bin/sh
# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied.

START_ORIGIN="$(pwd)"
cd "$(dirname "$0")/.."
PREDIX_MACHINE_HOME=$(pwd)

if [ -f "$PREDIX_MACHINE_HOME/yeti/start_yeti.sh" ]; then
    sh "$PREDIX_MACHINE_HOME"/yeti/stop_yeti.sh
else
    sh "$PREDIX_MACHINE_HOME"/machine/bin/predix/stop_container.sh
fi

cd "$START_ORIGIN"