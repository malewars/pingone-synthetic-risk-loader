#!/bin/sh
i=0
./sendrandom.sh
max=300
for i in `seq 2 $max`
do 
numbertoload=`jot -r 1 1 600`
echo "I will sleep $numbertoload seconds"
sleep $numbertoload
echo "time to make the donuts"
echo "----"
./sendrandom.sh
echo "-----"
done
