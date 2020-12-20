#!/bin/bash
#=======================================================================
# This script can be run during or after overcloud deployment.
# This will try to show you the tasks that are running on different 
# Overcloud nodes during the deployment.
#=======================================================================

. /home/stack/stackrc
INPUT=""
if [[ ! -z $1 ]]; then
	INPUT=$1
	echo "Filtering on $1"
fi
HEADER="Node Name,Node Status,IP Address,Task Action,Task Status,Config Name, Config Group, Creation Time"

SERVERS=`openstack server list -f csv | grep -v "ID"| sed s/ctlplane=//g`
CURRENTTASKS=`openstack software deployment list -f csv | grep -v "id"`
CONFIGLIST=`openstack software config list -f csv`

echo "$HEADER"
for items in $CURRENTTASKS; do
    SERVERID=`echo "$items" | awk -F "," '{print $3}'`
    CONFIGID=`echo "$items" | awk -F "," '{print $2}'`
    OVERCLOUDNODE=`echo "$SERVERS" | grep $SERVERID | awk -F "," '{print $2 "," $3 "," $4}'`
    TASKSTATUS=`echo "$items" | awk -F "," '{print $4","$5}'`
    CONFIGDETAILS=`echo "$CONFIGLIST" | grep $CONFIGID | awk -F "," '{print $2","$3","$4}'`
    echo "$OVERCLOUDNODE,$TASKSTATUS,$CONFIGDETAILS" | grep "$INPUT"
done
