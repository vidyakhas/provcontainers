#!/bin/bash
chown -R predixmachine:predixmachine /PredixMachine
chown -R predixmachine:predixmachine /data
chown predixmachine:predixmachine /var/run/docker.sock
su - predixmachine - /PredixMachine/bin/docker_start_predixmachine.sh