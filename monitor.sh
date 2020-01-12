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

# number of blocks to fall behind before restart
RANGE=10

# block counter set to 0 at startup
COUNTER=0

# path to jcli
JCLI="jcli"
JCLI_PORT=3100

# path to log file
LOG_FILE="/home/coconut/logs/block.log"

# network stuff (dont touch)

LAST_BLOCK=""
START_TIME=$SECONDS

# how many seconds should we wait if no blocks show up
RESTART_GT=180

# display output headers
echo "/////////////////////////////////////////////////////////////////////////////////////"
echo "///////////////////////// JORMUNGANDR NODE MONITOR //////////////////////////////////"
echo "/////////////////////////////////////////////////////////////////////////////////////"
echo ""
echo "TODAY DATE | EP | SLOT# | EXP TIME | LOC TIME | HEIGHT | TIP | LAST HASH | COUNTER"
echo ""

# write headers to log file
echo "/////////////////////////////////////////////////////////////////////////////////////" >> ${LOG_FILE}
echo "///////////////////////// JORMUNGANDR NODE MONITOR //////////////////////////////////" >> ${LOG_FILE}
echo "/////////////////////////////////////////////////////////////////////////////////////" >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}
echo "TODAY DATE | EP | SLOT# | EXP TIME | LOC TIME | HEIGHT | TIP | LAST HASH | COUNTER" >> ${LOG_FILE}
echo ""  >> ${LOG_FILE}

# start the monitoring
while true
do  
    
    #todays date
    DATE=$(date '+%Y-%m-%d')

    # majority tip
    MAJOR_TIP=$(curl -s https://pooltool.s3-us-west-2.amazonaws.com/stats/stats.json | jq -r .majoritymax)

    # the time your node got the block
    TIME=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastReceivedBlockTime | awk '{print $2}' | cut -c 13- | rev | cut -c 8- | rev)
    
    # last block hash 9 chars
    LAST_HASH=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockHash | awk '{print $2}' | cut -c 1-9)
    
    # last block number
    LATEST_BLOCK=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockHeight | awk '{print $2}' | rev | cut -c 2- | rev | cut -c 2-)
    
    # last slot selected 
    LATEST_SLOT=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockDate | awk '{print $2}' | rev | cut -c 2- | rev | cut -c 5- )
    
    # the time the last block as registered on the network
    LAST_BLOCK_TIME=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockTime | awk '{print $2}' | cut -c 13- | rev | cut -c 8- | rev)
    
    # current epoch number
    EPOCH=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockDate | awk '{print $2}' | cut -c -3 | cut -c 2- )
    
    #make it happen
    if [ "$LATEST_BLOCK" > 0 ]; then
        if [ "$LATEST_BLOCK" != "$LAST_BLOCK" ]; then
            # blocks since last restart counter
            COUNTER=$((COUNTER+1))
            
            # logging to screen and file
            START_TIME=$(($SECONDS))
    
         # if a block isnt shown its probably a double block
        if [ "$LATEST_BLOCK" != $(($LAST_BLOCK+1)) ]; then
               echo "MULTIPLE BLOCKS CREATED AT BLOCK:  $(($LAST_BLOCK+1))"
               echo "MULTIPLE BLOCKS CREATED AT BLOCK:  $(($LAST_BLOCK+1))" >> ${LOG_FILE}
            fi
    
         # restart is the node gets too far behind the major_tip 
         if [ "$LATEST_BLOCK" -lt $(($MAJOR_TIP-$RANGE)) ]; then
            echo "TOO FAR BEHIND MAJOR TIP. RESTARTING NODE."
            echo "TOO FAR BEHIND MAJOR TIP. RESTARTING NODE." >> ${LOG_FILE}
            sudo service jorg restart
         fi

            echo "${DATE} | ${EPOCH} | ${LATEST_SLOT} | ${LAST_BLOCK_TIME} | ${TIME} | ${LATEST_BLOCK} | ${MAJOR_TIP} | ${LAST_HASH} | ${COUNTER}"
            echo "${DATE} | ${EPOCH} | ${LATEST_SLOT} | ${LAST_BLOCK_TIME} | ${TIME} | ${LATEST_BLOCK} | ${MAJOR_TIP} | ${LAST_HASH} | ${COUNTER}" >> ${LOG_FILE}
            LAST_BLOCK="$LATEST_BLOCK"
 else
            ELAPSED_TIME=$(($SECONDS - $START_TIME))
            if [ "$ELAPSED_TIME" -gt "$RESTART_GT" ]; then
               
               # log to screen and file
                echo "//////////////////////////////////////////////////////////////////////////////////"
                echo "${DATE} | ${TIME} | Restarting Jormungandr. | Waited ${ELAPSED_TIME} seconds for block."

                echo "//////////////////////////////////////////////////////////////////////////////////" >> ${LOG_FILE}
                echo "${DATE} | ${TIME} | Restarting Jormungandr. | Waited ${ELAPSED_TIME} seconds for block." >> ${LOG_FILE}

                # restart service after getting stuck
                sudo service jorg restart
                LAST_BLOCK="$LATEST_BLOCK"

                # reset counter on restart
                COUNTER=0
                
                # take a break while the node bootstraps
                echo "Sleeping for 90 sec."
                sleep 90
                
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
