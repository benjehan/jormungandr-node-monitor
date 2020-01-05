#!/bin/bash
#
# Created by: Uruncle @ https://adage.app Cardano Stake Pool
# Updated by: Dogpatch Media @ https://coconutpool.com
#
# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
# Notes:
#
# Jormungandr must be running as a service in order for the node to be reset.
#

### CONFIGURATION

# create and reset temp file for counter on startup
TEMPFILE=/tmp/counter.tmp
echo 0 > $TEMPFILE  

# path to jcli
JCLI="jcli"
JCLI_PORT=3100

# path to log file
LOG_FILE=/home/coconut/logs/block.log

# network stuff (dont touch)
LAST_BLOCK=""
START_TIME=$SECONDS

# how many seconds should we wait if no blocks show up
RESTART_GT=180

while true
do  
    
    #todays date and time
    DATE=$(date '+%Y-%m-%d')
    TIME=$(date '+%H:%M:%S')
    
    # info from the node
    LATEST_BLOCK=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockHeight | awk '{print $2}' | rev | cut -c 2- | rev | cut -c 2-)
    LATEST_SLOT=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockDate | awk '{print $2}' | rev | cut -c 2- | rev | cut -c 5- )
    LAST_BLOCK_TIME=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockTime | awk '{print $2}' | cut -c 13- | rev | cut -c 8- | rev)
    EPOCH=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockDate | awk '{print $2}' | cut -c -3 | cut -c 2- )
    
    #make it happen
    if [ "$LATEST_BLOCK" > 0 ]; then
        if [ "$LATEST_BLOCK" != "$LAST_BLOCK" ]; then
            # blocks since last restart counter
            COUNTER=$((COUNTER+1))
            
            # logging to screen and file
            START_TIME=$(($SECONDS))
            echo "${DATE} | Epoch: ${EPOCH} | Slot: ${LATEST_SLOT} | Explorer: ${LAST_BLOCK_TIME} | Local: ${TIME} | Block: ${LATEST_BLOCK} | Count: ${BLOCK_COUNT}"
            echo "${DATE} | Epoch: ${EPOCH} | Slot: ${LATEST_SLOT} | Explorer: ${LAST_BLOCK_TIME} | Local: ${TIME} | Block: ${LATEST_BLOCK} | Count: ${BLOCK_COUNT}" >> ${LOG_FILE}
            LAST_BLOCK="$LATEST_BLOCK"
        else
            ELAPSED_TIME=$(($SECONDS - $START_TIME))
            if [ "$ELAPSED_TIME" -gt "$RESTART_GT" ]; then
                # log to screen and file
                echo "//////////////////////////////////////////////////////////////////////////////////"
                echo "${DATE} | ${TIME} | Restarting Jormungandr. | Waited ${ELAPSED_TIME} for block."

                echo "//////////////////////////////////////////////////////////////////////////////////" >> ${LOG_FILE}
                echo "${DATE} | ${TIME} | Restarting Jormungandr. | Waited ${ELAPSED_TIME} for block." >> ${LOG_FILE}

                # restart service after getting stuck
                sudo service jorg restart
                LAST_BLOCK="$LATEST_BLOCK"
                echo "Sleeping for 90 sec."
                sleep 90
                
                # reset counter on restart
                 echo 0 > $TEMPFILE 
            fi
        fi
    else
        # there is no connection to the node
        echo "Unable to connect to Jormungandr."
        
        # Reset time
        START_TIME=$(($SECONDS))
    fi
    sleep 20
done

exit 0
