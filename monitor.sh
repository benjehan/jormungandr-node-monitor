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
# set tab spacing
tabs 5

# number of blocks behind consesnsus tip before restarting
GET_BEHIND=100

# block counter set to 0 at startup
# dont change this or else the world will end
COUNTER=0


# path to jcli
JCLI="jcli"
JCLI_PORT=3100

# path to log file
LOG_FILE="/home/coconut/logs/stuck.log"

# network stuff
# if you change this, oh man, its gonna be bad

LAST_BLOCK=""

# time stuff
START_TIME=$SECONDS

# how many seconds should we wait if no blocks show up
# i like about 6 minutes
RESTART_GT=3600

# display output headers
echo "/////////////////////////////////////////////////////////////////////////////////////"
echo "///////////////////////// JORMUNGANDR NODE MONITOR //////////////////////////////////"
echo "/////////////////////////////////////////////////////////////////////////////////////"
echo ""
printf "===DATE=== \t EP \t SLOT \t EXP. TIME \t LOCAL TIME \t DIFFS \t SHLLY \t LOCAL \t POOLTL \t HASH \t FORK \t COUNT \n"
printf "===DATE=== \t EP \t SLOT \t EXP. TIME \t LOCAL TIME \t DIFFS \t SHLLY \t LOCAL \t POOLTL \t HASH \t FORK \t COUNT \n" >> ${LOG_FILE}
echo ""

# start the monitoring
while true
do  
    
    # multiple blocks starting state
    MULTIBLOCK="NO "

    #todays date
    DATE=$(date '+%Y-%m-%d')

    # majority tip
    MAJOR_TIP=$(curl -s https://pooltool.s3-us-west-2.amazonaws.com/stats/stats.json | jq -r .majoritymax)

    # the time your node got the block
    TIME=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastReceivedBlockTime | awk '{print $2}' | cut -c 13- | rev | cut -c 8- | rev)    
    # last block hash 9 chars
    LAST_HASH=$($JCLI rest v0 node stats get --host "http://127.0.0.1:${JCLI_PORT}/api" | grep lastBlockHash | awk '{print $2}' | cut -c 1-5)
    
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
               
               MULTIBLOCK="YES"
        fi
    
         # restart is the node gets too far behind the major_tip 
         if [ "$LATEST_BLOCK" -lt $(($MAJOR_TIP-$GET_BEHIND)) ]; then
            echo "TOO FAR BEHIND MAJOR TIP. RESTARTING NODE."
            echo "TOO FAR BEHIND MAJOR TIP. RESTARTING NODE." >> ${LOG_FILE}
            sudo service jorg restart
         fi
        # get last block count from shelley explorer
        shelleyExplorerJson=`curl -X POST -H "Content-Type: application/json" --data '{"query": " query {   allBlocks (last: 3) {    pageInfo { hasNextPage hasPreviousPage startCursor endCursor  }  totalCount  edges {    node {     id  date { slot epoch {  id  firstBlock { id  }  lastBlock { id  }  totalBlocks }  }  transactions { totalCount edges {   node {    id  block { id date {   slot   epoch {    id  firstBlock { id  }  lastBlock { id  }  totalBlocks   } } leader {   __typename   ... on Pool {    id  blocks { totalCount  }  registration { startValidity managementThreshold owners operators rewards {   fixed   ratio {  numerator  denominator   }   maxLimit } rewardAccount {   id }  }   } }  }  inputs { amount address {   id }  }  outputs { amount address {   id }  }   }   cursor }  }  previousBlock { id  }  chainLength  leader { __typename ... on Pool {  id  blocks { totalCount  }  registration { startValidity managementThreshold owners operators rewards {   fixed   ratio {  numerator  denominator   }   maxLimit } rewardAccount {   id }  } }  }    }    cursor  }   } }  "}' https://explorer.incentivized-testnet.iohkdev.io/explorer/graphql 2> /dev/null`
        shelleyLastBlockCount=`echo $shelleyExplorerJson | grep -m 1 -o '"chainLength":"[^"]*' | cut -d'"' -f4 | awk '{print $NF}'`
        shelleyLastBlockCount=`echo $shelleyLastBlockCount|cut -d ' ' -f3`

        # calculate time difference between shelley and local
        SBT=$(date -d "${LAST_BLOCK_TIME} ${DATE}" +%s)
        LBT=$(date -d "${TIME} ${DATE}" +%s)
        TDIFF=$(($SBT-$LBT))

            printf "${DATE} \t ${EPOCH} \t ${LATEST_SLOT} \t ${LAST_BLOCK_TIME} \t ${TIME} \t ${TDIFF}s \t ${shelleyLastBlockCount} \t ${LATEST_BLOCK} \t ${MAJOR_TIP} \t ${LAST_HASH} \t ${MULTIBLOCK} \t ${COUNTER} \n"
            printf "${DATE} \t ${EPOCH} \t ${LATEST_SLOT} \t ${LAST_BLOCK_TIME} \t ${TIME} \t ${TDIFF}s \t ${shelleyLastBlockCount} \t ${LATEST_BLOCK} \t ${MAJOR_TIP} \t ${LAST_HASH} \t ${MULTIBLOCK} \t ${COUNTER} \n" >> ${LOG_FILE}
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
                echo "Waiting for Jormungandr to Bootstrap.. (this coule be awhile)"
                sleep 45
                
            fi
        fi
    else
        # there is no connection to the node
        echo "Waiting.."
        COUNTER=0
        # Reset time
        START_TIME=$(($SECONDS))
    fi
    sleep 20
done

exit 0
