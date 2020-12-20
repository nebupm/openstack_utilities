#! /usr/bin/env bash
#===============================================================================================================
# Author: Nebu Mathews mail-to: nebupm@gmail.com
#===============================================================================================================
#   This script will monitor the progress of each migration. Cold or Live.
#
# Argument 1 (Mandatory) : Instance ID of the instance getting migrated.
#
# Usage Example:
#	 ./migration_status.sh <Instance ID>
#
#===============================================================================================================
# Function to log message on logfile. This is introduced to have a uniform logging format.
function logmessage () {
    echo -e "`date \"+[%Y-%m-%d %H:%M:%S]\"`[$SCRIPTNAME]:$@"
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
    logmessage "[$INSTANCE_NAME][$INSTANCE_ID]: After Migration."  |& tee -a $CWD/"$NODE_FQDN"_migration.log
    openstack server show $INSTANCE_ID  |& tee -a $CWD/"$NODE_FQDN"_migration.log
    rm -f $MIGRATION_DATA_FILE
    logmessage "##############################################################"  |& tee -a $CWD/"$NODE_FQDN"_migration.log
}

function poll_live_migration(){
    logmessage "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Getting $MIGRATION_TYPE migration details."
    MIGRATION_DATA_FILE=/tmp/$MIGRATION_TYPE.$INSTANCE_ID.$NODE_FQDN
    echo $HEADER
    while true; do
        nova server-migration-show $INSTANCE_ID $MIGRATION_ID > $MIGRATION_DATA_FILE 2>&1
        STATUS=$(grep "status" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}')
        DATETIME=$(date '+%Y-%m-%dT%H:%M:%S.%N')
        if [[ -z "$STATUS" ]]; then
            STATUS=$(nova migration-list | grep $INSTANCE_ID | awk -F "|" '{printf("%s,%s,%s\n",$2,$8,$13)}' | grep $MIGRATION_ID | awk -F "," '{print $2","$3}'  | sed s/\ //g)
            UPDATED_AT=$(echo $STATUS | awk -F "," '{print $NF}' | awk -F "." '{print $1}')
            echo "$DATETIME,$MIGRATION_ID,$INSTANCE_ID,$SOURCE_NODE -> $DESTINATION_NODE,Mem:$MEMORY_REMAINING_BYTES,Disk:$DISK_REMAINING_BYTES,$STATUS"
            rm -f $MIGRATION_DATA_FILE
            COUNT=1
            while true; do
                STATUS=$(openstack server show -c status -f value  $INSTANCE_ID | tr '[:upper:]' '[:lower:]')
                echo "$DATETIME,$MIGRATION_ID,$INSTANCE_ID,$SOURCE_NODE -> $DESTINATION_NODE,Mem:$MEMORY_REMAINING_BYTES,Disk:$DISK_REMAINING_BYTES,$STATUS,$UPDATED_AT"
                if ! [[ "$STATUS" =~ "migrating" ]]; then
                    break
                fi
                if [[ $COUNT -ge $RETRIES ]]; then
                    (exit 1)
                    logerrorstatus "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Exceeded $RETRIES retries. Exiting now."
                fi
                COUNT=$((COUNT+1))
                sleep 6
            done

            break;
        else
            MEMORY_REMAINING_BYTES=$(grep "memory_remaining_bytes" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}')
            DISK_REMAINING_BYTES=$(grep "disk_remaining_bytes" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}')
            DESTINATION_NODE=$(grep "dest_compute" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}')
            SOURCE_NODE=$(grep "source_compute" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}')
            UPDATED_AT=$(grep "updated_at" $MIGRATION_DATA_FILE | sed s/\|//g | awk '{print $NF}' | awk -F "." '{print $1}')
            echo "$DATETIME,$MIGRATION_ID,$INSTANCE_ID,$SOURCE_NODE -> $DESTINATION_NODE,Mem:$MEMORY_REMAINING_BYTES,Disk:$DISK_REMAINING_BYTES,$STATUS,$UPDATED_AT"
        fi
        sleep 2
    done
}

function poll_cold_migration(){
    logmessage "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Getting $MIGRATION_TYPE migration details."
    MIGRATION_DATA_FILE=/tmp/$MIGRATION_TYPE.$INSTANCE_ID.$NODE_FQDN
    nova migration-list --host $NODE_FQDN | grep $INSTANCE_ID | grep migrating | sed "s|\ ||g" > $MIGRATION_DATA_FILE 2>&1
    MIGRATION_ID=$(awk -F "|" '{print $2}' $MIGRATION_DATA_FILE)
    if [[ -z $MIGRATION_ID ]]; then
        logmessage "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Migration finished or Its not running."
        return
    fi
    echo $HEADER
    while true; do
        nova migration-list --host $NODE_FQDN | grep $INSTANCE_ID | grep $MIGRATION_ID | sed "s|\ ||g" > $MIGRATION_DATA_FILE 2>&1
        DATETIME=$(date '+%Y-%m-%dT%H:%M:%S.%N')
        STATUS=$(grep $MIGRATION_ID $MIGRATION_DATA_FILE | grep $INSTANCE_ID | awk -F "|" '{print $8}')
        SOURCE_NODE=$(grep $MIGRATION_ID $MIGRATION_DATA_FILE | grep $INSTANCE_ID | awk -F "|" '{print $3}')
        DESTINATION_NODE=$(grep $MIGRATION_ID $MIGRATION_DATA_FILE | grep $INSTANCE_ID | awk -F "|" '{print $4}')
        UPDATED_AT=$(grep $MIGRATION_ID $MIGRATION_DATA_FILE | grep $INSTANCE_ID | awk -F "|" '{print $13}' | awk -F "." '{print $1}')
        echo "$DATETIME,$MIGRATION_ID,$INSTANCE_ID,$SOURCE_NODE -> $DESTINATION_NODE,Mem:NAN,Disk:NAN,$STATUS,$UPDATED_AT"
        if [[ $STATUS =~ "finished" ]]; then
            rm -f $MIGRATION_DATA_FILE
            break
        fi
        sleep 5
    done
}

function main() {
    logmessage "[Before Migration]: ID=$INSTANCE_ID, Name=$INSTANCE_NAME, HOST=$NODE_FQDN"
    openstack server show $INSTANCE_ID
    COUNT=1
    while true; do
        MIGRATION_ID=$(nova server-migration-list $INSTANCE_ID | grep "|" | awk -F "|" '{print $2}' | grep -v "Id" | sed s/\ //g)
        logmessage "[$INSTANCE_NAME][$INSTANCE_ID]: Getting migration ID [$MIGRATION_ID]."
        if [[ -z "$MIGRATION_ID" ]]; then
                logmessage "[$INSTANCE_NAME][$INSTANCE_ID]: Checking the status of migration"
                STATUS=$(openstack server show -c status -f value  $INSTANCE_ID | tr '[:upper:]' '[:lower:]')
                if [[ "$STATUS" =~ "error" ]]; then
                    (exit 1)
                    logerrorstatus "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Live migration failed."
                elif [[ "$STATUS" =~ "migrating" ]]; then
                    logmessage "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Live migration started."
                    if [[ $COUNT -ge $RETRIES ]]; then
                        (exit 1)
                        logerrorstatus "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Exceeded $RETRIES retries."
                    fi
                elif [[ "$STATUS" =~ "active" ]]; then
                    (exit 1)
                    logerrorstatus "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Migration might be finished."
                elif [[ "$STATUS" =~ "resize" ]]; then
                    logmessage "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Cold migration"
                    MIGRATION_TYPE=cold
                    break
                else
                   (exit 1)
                   logerrorstatus "[$INSTANCE_NAME][$INSTANCE_ID][$STATUS]: Unknown status."
                fi
        else
            STATUS=$(openstack server show -c status -f value  $INSTANCE_ID | tr '[:upper:]' '[:lower:]')
            MIGRATION_TYPE=live
            break
        fi
        COUNT=$((COUNT+1))
    done    
    poll_"$MIGRATION_TYPE"_migration
}

#------------------------------------------------------------
# Main program execution start here.
#------------------------------------------------------------
SCRIPTNAME=`basename $0`
CWD=~
#trap 'script_exit $@' EXIT
trap script_exit EXIT
trap script_interrupt SIGINT

RETRIES=10
if [[ $# -eq 0 ]]; then
        logmessage "Usage: $0 <Instance ID>"
        exit 1
fi

if [[ -z $OS_AUTH_URL ]]; then
        (exit 1)
        logmessage "Source your rc file once before running this script"
        logmessage "Press any key..."
        read user_input
        exit 1
fi

INSTANCE_ID=$1
NODE_DETAILS=$(openstack server show -c OS-EXT-SRV-ATTR:hypervisor_hostname -c name $INSTANCE_ID -f value)
if [[ -z NODE_DETAILS ]]; then
    (exit 1)
    logerrorstatus "Couldnot get the details of the hypervisor server. Cannot continue."
fi
NODE_FQDN=$(echo "$NODE_DETAILS" | head -1)
INSTANCE_NAME=$(echo "$NODE_DETAILS" | tail -1)
HEADER="DATETIME,MIGRATION_ID,INSTANCE_ID,SOURCE_NODE -> DESTINATION_NODE,MEMORY_REMAINING_BYTES,DISK_REMAINING_BYTES,STATUS,UPDATED"

main |& tee -a $CWD/"$NODE_FQDN"_migration.log
exit 0
