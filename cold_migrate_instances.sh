#! /usr/bin/env bash
#===============================================================================================================
# Author: Nebu Mathews, Project: Openstack, Repo: overcloud-management mail-to: nmathews@ukcloud.com
#===============================================================================================================
#This script will cold migrate all SHUTOFF instances from this host.
#
# Argument 1 (Mandatory) : FQDN of the compute host.
#
# Usage Example:
#	 ./cold_migrate_instances.sh ock00016i2.frn00006.cni.ukcloud.com
#
#===============================================================================================================
function WaitForNSeconds(){
  if [[ -z "$1" ]]; then
    ITER=1
  else
    ITER=$1
  fi
  logmessage "[$FUNCNAME]: Sleeping for $ITER Seconds"
  for (( c=1; c<=$ITER; c++ )); do sleep 1;  printf "*"; done
  echo ""
}

function logmessage () {
    echo -e "`date \"+[%Y-%m-%d %H:%M:%S]\"`[$SCRIPTNAME]: $@"
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
    logmessage "Starting Cold Migration of SHUTOFF Instances"
    for id in $(openstack server list --all-projects --host $NODE_FQDN -c ID -c Status -f value | grep SHUTOFF | awk '{print $1}'); do
        logmessage "[$id]: Cold migration started"        
        nova migrate $id
        $WORKING_DIR/migration_status.sh $id
        logmessage "[$id]: Confirm Resize Instance"
        nova resize-confirm $id
        logerrorstatus "[$Id]: Resize Instance Failed"
        WaitForNSeconds $WAIT_TIME_IN_SEC
        openstack server show $id | tee -a ~/"$NODE_FQDN"_migration.log
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
    logmessage "Usage: $SCRIPTNAME <Node Name> <Wait time between migrations in seconds. Default: 60 seconds"
    exit 1
fi

WAIT_TIME_IN_SEC=${2:-60}
if [[ $WAIT_TIME_IN_SEC -lt 15 ]]; then
    logmessage "You have chosen a very low wait time. Setting it to lowest possible $WAIT_TIME_IN_SEC"
    WAIT_TIME_IN_SEC=15
fi
logmessage "Wait time between migrations: $WAIT_TIME_IN_SEC"
main