#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


catch() {
    local readonly ID=$1
    local readonly IPC_PATH=$2
    local readonly PID=$3
    local readonly DATADIR=$4

    mkdir -p test
    # Use the same block number now on to avoid modification during 
    # reading of info that create inconsistencies in the read results
    BLOCK_NUMBER=$(geth --exec "eth.blockNumber" attach ipc://$IPC_PATH)
    geth --exec "eth.pendingTransactions.length" \
                attach ipc://$IPC_PATH >> test/pendingTransactions-$ID.txt
    geth --exec "tx_count=0; \
                for(i = 0; i < $BLOCK_NUMBER; i++) { \
                tx_count += eth.getBlock(i).transactions.length;}; \
                tx_count;" \
                attach ipc://$IPC_PATH >> test/transactions-$ID.txt
    
    geth --exec "diff=[]; for(i = 0; i < $BLOCK_NUMBER; i++) { \
                 diff.push(eth.getBlock(i).difficulty); }; diff;" \
                attach ipc://$IPC_PATH >> /tmp/final_difficulty-$ID.txt

    
    geth --exec "timestamps=[]; for(i = 0; i < $BLOCK_NUMBER; i++) {\
                timestamps.push(eth.getBlock(i).timestamp); }; timestamps; " \
                attach ipc://$IPC_PATH >> /tmp/final_timestamps-$ID.txt
    
    # get the run
    RUN=0
    while [[ -a test/final_difficulty-$ID-$RUN ]];
    do 
        RUN=$((RUN+1))
    done 

    # Put each entry of the javascript list in a separate line
    cat /tmp/final_difficulty-$ID.txt | tr "[]" " " | tr " " "\n" > test/final_difficulty-$ID-$RUN.txt
    cat /tmp/final_timestamps-$ID.txt | tr "[]" " " | tr " " "\n" > test/final_timestamps-$ID-$RUN.txt

    rm /tmp/final_timestamps-$ID.txt
    rm /tmp/final_timestamps-$ID.txt

    rm /tmp/final_timestamps-$ID.txt
    rm /tmp/final_timestamps-$ID.txt


    echo $BLOCK_NUMBER >> test/block_number-$ID.txt
    
    # Do other useful stuffs, e.g. upload stats to central server and so on
    # Sends SIGNAL to child/sub processes
    kill -HUP $PID
    trap - SIGUSR1 # clear the trap
    du -h $DATADIR >> test/blockchain_dir_size-$ID.txt
    echo "---" >> test/blockchain_dir_size-$ID.txt
    printf "Done ..."
    exit 0
}


# geth --exec "eth.blockNumber; tx_count=0; for(i = 0; i < eth.blockNumber; i++) { tx_count += eth.getBlock(i).transactions.length;}; tx_count" attach http://10.14.67.157:8545 

main() {
    local readonly ID=$1
    local readonly DATADIR=$3
    local readonly IPC_PATH=$7
    shift # Forget about the first argument
    local GETH_ARGS="$@"

    geth $GETH_ARGS &
    
    local readonly PID=$!
    
    trap "catch $ID $IPC_PATH $PID $DATADIR" SIGUSR1
    
    # The parent program should be alive when the signal arrives
    sleep 100000
}

main $ARGS
