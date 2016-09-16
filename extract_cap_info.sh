#!/bin/bash

CAP_LOG_FILE="caps.log"
CPU_USAGE_OUTPUT_FILE="cpu_usage.csv"

echo "scaling_period,cap_change,start_cap,cpu_usage,cap_changes" > $CPU_USAGE_OUTPUT_FILE

for line in `cat $CAP_LOG_FILE`
do
	CAPS="`echo $line | awk -F "-" {'print $2'} | sed 's/,/ /g'`"
	PARAMETERS="`echo $line | awk -F "-" {'print $1'}`"
	SCALING_PERIOD="`echo $PARAMETERS | awk -F "," {'print $1'}`"
	CAP_CHANGE="`echo $PARAMETERS | awk -F "," {'print $2'}`"
	START_CAP="`echo $PARAMETERS | awk -F "," {'print $3'}`"

	RESOURCE_USAGE=0
	CAP_CHANGES=0
	LAST_CAP=$START_CAP

	for cap in $CAPS
	do
		RESOURCE_USAGE=$(( $SCALING_PERIOD*$cap + $RESOURCE_USAGE ))
		
		if [ $LAST_CAP -ne $cap ]
		then
			CAP_CHANGES=$(( $CAP_CHANGES + 1 ))
		fi

		LAST_CAP=$cap
	done

	echo "$SCALING_PERIOD,$CAP_CHANGE,$START_CAP,$RESOURCE_USAGE,$CAP_CHANGES" >> $CPU_USAGE_OUTPUT_FILE
done

