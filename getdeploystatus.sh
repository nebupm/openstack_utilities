#! /usr/bin/env bash

#============================================================================#
# This script can be run during or after overcloud deployment.               #
# This will try to show you the tasks that are running on different          #
# Overcloud nodes during the deployment.                                     #
#                                                                            #
# Usage Example:                                                             #
#	 ./getdeploystatus.sh <TEXT to FILTER, Case sensitive>                   #
#                                                                            #
#  Copyright (C) 2020  Nebu Mathews                                          #
#                                                                            #
#  This program is free software: you can redistribute it and/or modify      #
#  it under the terms of the GNU General Public License as published by      #
#  the Free Software Foundation, either version 3 of the License, or         #
#  (at your option) any later version.                                       #
#  This program is distributed in the hope that it will be useful,           #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of            #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
#  GNU General Public License for more details.                              #
#                                                                            #
#  You should have received a copy of the GNU General Public License         #
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.    #
#============================================================================#

if [[ -z $OS_AUTH_URL ]]; then
    echo "source your rc file before running this script"
    exit 1
fi


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
