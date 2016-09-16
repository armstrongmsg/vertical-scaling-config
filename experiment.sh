#!/bin/bash

VM_USER="armstrong"
VM_IP="192.168.122.32"
VM_NAME="lubuntu1"

SCALING_PERIOD=$1
CAP_CHANGE=$2
START_CAP=$3

COMPLETION=0
START_TIME=`date +%s`
EXPECTED_TIME=260
FATORIAL_N=100
CAPS="$START_CAP"

RESULTS_FILE="total_time.csv"

# set starting cap
virsh schedinfo $VM_NAME --set vcpu_quota=$(( $START_CAP*1000 )) > /dev/null

# start application
ssh $VM_USER@$VM_IP /home/$VM_USER/vertical-scaling-config/application.sh $FATORIAL_N &

while [ $COMPLETION -ne 100 ]
do
	sleep $SCALING_PERIOD
	
	CAP=`virsh schedinfo $VM_NAME | grep vcpu_quota | awk '{print $3}'`
	CAP=$(( $CAP/1000 ))
	CAPS="$CAPS,$CAP"

	COMPLETION="`ssh $VM_USER@$VM_IP tail -n 1 /home/$VM_USER/job.progress`"
	USED_TIME=$(( `date +%s` - $START_TIME ))

	TIME_PROGRESS="`echo 100*$USED_TIME/$EXPECTED_TIME | bc`"
	
	if [ $(( $TIME_PROGRESS - $COMPLETION )) -gt 10 ]
	then	
		NEXT_CAP=$(( $CAP + $CAP_CHANGE ))

		if [ $NEXT_CAP -gt 100 ]
		then
			NEXT_CAP=100
		fi

		virsh schedinfo $VM_NAME --set vcpu_quota=$(( $NEXT_CAP*1000 )) > /dev/null
	fi

	if [ $(( $COMPLETION - $TIME_PROGRESS )) -gt 30 ]
	then	
		NEXT_CAP=$(( $CAP - $CAP_CHANGE ))

		if [ $NEXT_CAP -lt 10 ]
		then
			NEXT_CAP=10
		fi

		virsh schedinfo $VM_NAME --set vcpu_quota=$(( $NEXT_CAP*1000 )) > /dev/null
	fi
done

virsh schedinfo $VM_NAME --set vcpu_quota=100000 > /dev/null

START_TIME="`ssh $VM_USER@$VM_IP cat /home/$VM_USER/start.time`"
END_TIME="`ssh $VM_USER@$VM_IP cat /home/$VM_USER/end.time`"
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo "$SCALING_PERIOD,$CAP_CHANGE,$START_CAP,$TOTAL_TIME" >> $RESULTS_FILE
echo "$SCALING_PERIOD,$CAP_CHANGE,$START_CAP-$CAPS" >> "caps.log"
