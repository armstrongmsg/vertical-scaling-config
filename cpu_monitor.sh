#!/bin/bash

CPU_USAGE_FILE="cpu.usage"

echo "timestamp;usage" > $CPU_USAGE_FILE

while : 
do
	USAGE=`sar 1 1 | awk 'FNR == 4 {print $8}'`
	echo "`date +%s`;$USAGE" >> $CPU_USAGE_FILE
done
