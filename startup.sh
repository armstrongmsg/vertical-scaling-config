#!/bin/bash

PERIOD_SCALING_LEVELS="10 60"
CAP_CHANGE_LEVELS="5 15"
START_CAP_LEVELS="25 75"
REPEAT_NUMBER=10
RESULTS_FILE="total_time.csv"

echo "scaling_period,cap_change,start_cap,total_time" > $RESULTS_FILE
echo "" > "caps.log"

./cpu_monitor.sh &
PID_MONITOR="$!"

for r in `seq 1 $REPEAT_NUMBER`
do
	echo "Repeat:$r"
	for PARAMETERS in {10,60},{5,25},{25,75}
	do
		PERIOD_SCALING="`echo $PARAMETERS | awk -F "," '{print $1}'`"
		CAP_CHANGE="`echo $PARAMETERS | awk -F "," '{print $2}'`"
		START_CAP="`echo $PARAMETERS | awk -F "," '{print $3}'`"
		
		echo "Parameters:period_scaling=$PERIOD_SCALING,cap_change=$CAP_CHANGE,start_cap=$START_CAP"	
		
		./experiment.sh $PERIOD_SCALING $CAP_CHANGE $START_CAP
	done
done

kill $PID_MONITOR
