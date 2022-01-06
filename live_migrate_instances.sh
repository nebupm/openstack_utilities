#! /usr/bin/env bash
#===============================================================================================================
# Author: Nebu Mathews, Project: Openstack, Repo: overcloud-management mail-to: nmathews@ukcloud.com
#===============================================================================================================
# This script will live migrate all ACTIVE instances from this host.
#
# Argument 1 (Mandatory) : FQDN of the compute host.
#
# Usage Example:
#	 ./live_migrate_instances.sh ock00016i2.frn00006.cni.ukcloud.com
#
#===============================================================================================================
function WaitForNSeconds(){
  if [[ -z "$1" ]]; then
    ITER=1
  else
    ITER=$1
  fi
  log_info_message "[$FUNCNAME]: Waiting for $ITER Seconds"
  for (( c=1; c<=$ITER; c++ )); do sleep 1;  printf "*"; done
  echo ""
}

function main(){
    if [[ -z $OS_AUTH_URL ]]; then
        (exit 1)
        log_error_and_exit "source your rc file before running this script"
    fi

    if ! [[ -f "$WORKING_DIR/migration_status.sh" ]]; then
        (exit 1)
        log_error_and_exit "Cant find migration_status.sh file. This is required to monitor migration progress."
    fi

    NODE_FQDN=$1
    RE_EXP="^-"
    if [[ $NODE_FQDN =~ $RE_EXP ]] || [[ -z $NODE_FQDN ]] ; then
        log_info_message "Usage: $SCRIPTNAME <Node Name> <Wait time between migrations in seconds. Default: 60 seconds> <Exclude Instances. Example: master|worker|haproxy|Prod>"
        exit 1
    fi

    WAIT_TIME_IN_SEC=${2:-60}
    if [[ $WAIT_TIME_IN_SEC -lt 15 ]]; then
        WAIT_TIME_IN_SEC=15
        log_info_message "You have chosen a very low wait time. Setting it to lowest possible $WAIT_TIME_IN_SEC"
    fi
    log_info_message "Wait time between migrations: $WAIT_TIME_IN_SEC"
    EXCLUSION_FILTER=$3
    if [[ -z $EXCLUSION_FILTER ]]; then
        log_info_message "No exclusion filter provided by user, migrating all instances."
        FILTER="^$"
    else
        FILTER=$EXCLUSION_FILTER
        log_info_message "Exclusion filter applied: $FILTER. These instances will not be migrated."
    fi

    NODE_FQDN_STATUS=$(openstack compute service list --service nova-compute -f value -c Host -c Status | grep $NODE_FQDN | awk '{print $NF}')
    if ! [[ "$NODE_FQDN_STATUS" =~ "disabled" ]]; then
        (exit 1)
        log_error_and_exit "nova-compute service is enabled on this host. Please disable before any maintenance. Command: openstack compute service set --disable $NODE_FQDN nova-compute"
    fi

    if [[ -z $EXCLUSION_FILTER ]]; then
        log_info_message "Starting Live Migration of ACTIVE Instances."
    else
        log_info_message "Starting Live Migration of ACTIVE Instances. Excluding Instances : $FILTER"
    fi
    for data in $(openstack server list --all-projects --host $NODE_FQDN -c ID -c Name -c Status -f csv | grep ACTIVE | grep -v -E "$FILTER"); do 
        id=$(echo $data | awk -F "," '{print $1}' | sed "s|^\"||g" | sed "s|\"$||g")
        name=$(echo $data | awk -F "," '{print $2}' | sed "s|^\"||g" | sed "s|\"$||g")
        status=$(echo $data | awk -F "," '{print $NF}' | sed "s|^\"||g" | sed "s|\"$||g")
        log_info_message "[$id][$name][$status]: Live migration started"
        nova live-migration $id
        $WORKING_DIR/migration_status.sh $id
        WaitForNSeconds $WAIT_TIME_IN_SEC
    done
}

#------------------------------------------------------------
# Main program execution start here.
#------------------------------------------------------------
# Includes to go here
#------------------------------------------------------------
source $(dirname $0)/logger.sh
trap script_exit EXIT
trap script_interrupt SIGINT

FULL_PATH=$(realpath $0)
SCRIPTNAME=$(basename $FULL_PATH)
WORKING_DIR=$(dirname $FULL_PATH)
TMPFILE=$(mktemp)

main "$@"
