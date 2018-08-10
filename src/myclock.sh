#!/bin/sh

cd /mnt/us/extensions/kindle-weather-clock/src/
EXTENSION=/mnt/us/extensions/


${EXTENSION}../etcl/bin/etcl  ${EXTENSION}/MyClock/src/loveCalendar.tcl > log.txt
