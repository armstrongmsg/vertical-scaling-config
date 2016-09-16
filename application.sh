#!/bin/bash

FACTORIAL_N=$1
PROGRESS_FILE="job.progress"

function factorial()
  if (( $1 < 2 ))
  then
    echo 1
  else
    echo "$1 * $(factorial $(( $1 - 1 )))" | bc
  fi

echo "`date +%s`" > "start.time"
echo "0" > $PROGRESS_FILE

for i in `seq 1 100` ;
do
        factorial $FACTORIAL_N > /dev/null
        echo $i >> $PROGRESS_FILE
done

echo "`date +%s`" > "end.time"
