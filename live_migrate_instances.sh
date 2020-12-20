#! /usr/bin/env bash

#============================================================================#
# This script will live migrate all ACTIVE instances from this host. This    #
# will achieve a result similar to nova evacuate command, however, this is   #
# more controlled and the user has the freedon to stop the migration but     #
# breaking the script execution and do required actions before resuming      #
# again. This script also depends on migration_status.sh script, it is used  #
# to monitor the progress of migration. It will be polling nova migration    #
# list and getting an upto date status every 5 seconds.                      #
#                                                                            #
# Argument 1 (Mandatory) : FQDN of the compute host.                         #
# Argument 2 (Optional) : Number of seconds to wait between migrations.      #
#                         Default : 60 seconds.                              #
# Argument 3 (Optional) : List of instances to exclude from the migration.   #
#                         Example "Prod|master|Customer1".                   #
#                         Default : No exclusion.                            #
#                                                                            #
# ./live_migrate_instances.sh <Compute Host name> 15 "Prod|master|Customer1" #
# You can extract this name from the following openstack.                    #
# openstack scompute service list --service nova-compute                     #
#                                                                            #
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

function WaitForNSeconds(){
  if [[ -z "$1" ]]; then
    ITER=1
  else
    ITER=$1
  fi
  logmessage "[$FUNCNAME]: Waiting for $ITER Seconds"
  for (( c=1; c<=$ITER; c++ )); do sleep 1;  printf "*"; done
  echo ""
}

function logmessage () {
    echo -e "`date \"+[%Y-%m-%d %H:%M:%S]\"`[$SCRIPTNAME]:${@}" >&2
}

function logerrorstatus() {
    RETURNCODE=$?
    if [[ $RETURNCODE  -ne 0 ]]; then
        logmessage "[$FUNCNAME][$RETURNCODE]: ${@}"
        exit 1
    fi
}

function script_interrupt(){
    logmessage "[$FUNCNAME] : User Entered CTRL-C"
    exit 1
}

function script_exit(){
    logmessage "##############################################################"
}

function main(){
    NODE_FQDN_STATUS=$(openstack compute service list --service nova-compute -f value -c Host -c Status | grep $NODE_FQDN | awk '{print $NF}')
    if ! [[ "$NODE_FQDN_STATUS" =~ "disabled" ]]; then
        (exit 1)
        logerrorstatus "nova-compute service is enabled on this host. Please disable before any maintenance. Command: openstack compute service set --disable $NODE_FQDN nova-compute"
    fi

    if [[ -z $EXCLUSION_FILTER ]]; then
        logmessage "Starting Live Migration of ACTIVE Instances."
    else
        logmessage "Starting Live Migration of ACTIVE Instances. Excluding Instances : $FILTER"
    fi
    for data in $(openstack server list --all-projects --host $NODE_FQDN -c ID -c Name -c Status -f csv | grep ACTIVE | grep -v -E "$FILTER"); do 
        id=$(echo $data | awk -F "," '{print $1}' | sed "s|^\"||g" | sed "s|\"$||g")
        name=$(echo $data | awk -F "," '{print $2}' | sed "s|^\"||g" | sed "s|\"$||g")
        status=$(echo $data | awk -F "," '{print $NF}' | sed "s|^\"||g" | sed "s|\"$||g")
        logmessage "[$id][$name][$status]: Live migration started"
        nova live-migration $id
        $WORKING_DIR/migration_status.sh $id
        WaitForNSeconds $WAIT_TIME_IN_SEC
    done
}
#------------------------------------------------------------
# Main program execution start here.
#------------------------------------------------------------
trap script_exit EXIT
trap script_interrupt SIGINT
FULL_PATH=$(realpath $0)
SCRIPTNAME=$(basename $FULL_PATH)
WORKING_DIR=$(dirname $FULL_PATH)

if [[ -z $OS_AUTH_URL ]]; then
        (exit 1)
        logerrorstatus "source your rc file before running this script"
fi

if ! [[ -f "$WORKING_DIR/migration_status.sh" ]]; then
    (exit 1)
    logerrorstatus "Cant find migration_status.sh file. This is required to monitor migration progress."
fi

NODE_FQDN=$1
RE_EXP="^-"
if [[ $NODE_FQDN =~ $RE_EXP ]] || [[ -z $NODE_FQDN ]] ; then
    logmessage "Usage: $SCRIPTNAME <Node Name> <Wait time between migrations in seconds. Default: 60 seconds> <Exclude Instances. Example: master|worker|haproxy|Prod>"
    exit 1
fi

WAIT_TIME_IN_SEC=${2:-60}
if [[ $WAIT_TIME_IN_SEC -lt 15 ]]; then
    WAIT_TIME_IN_SEC=15
    logmessage "You have chosen a very low wait time. Setting it to lowest possible $WAIT_TIME_IN_SEC"
fi
logmessage "Wait time between migrations: $WAIT_TIME_IN_SEC"
EXCLUSION_FILTER=$3
if [[ -z $EXCLUSION_FILTER ]]; then
    logmessage "No exclusion filter provided by user, migrating all instances."
    FILTER="^$"
else
    FILTER=$EXCLUSION_FILTER
    logmessage "Exclusion filter applied: $FILTER. These instances will not be migrated."
fi

main
