#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


catch() {
    local readonly ID=$1
    local readonly IPC_PATH=$2
    local readonly PID=$3

    printf "Dump metrics to metrics.txt\n"
    mkdir -p test
    # geth --exec "debug.metrics(true)" attach ipc:$1 > test/metrics.txt
    geth --exec "eth.blockNumber" attach ipc://$IPC_PATH >> test/block_number-$ID.txt
    geth --exec "tx_count=0; \
                for(i = 0; i < eth.blockNumber; i++) { \
                tx_count += eth.getBlock(i).transactions.length;}; \
                tx_count;" \
                attach ipc://$IPC_PATH >> test/transactions-$ID.txt
    
    geth --exec "diff=[]; for(i = 0; i < eth.blockNumber; i++) { \
                 diff.push(eth.getBlock(i).difficulty); }; diff;" \
                attach ipc://$IPC_PATH >> test/final_difficulty-$ID.txt
    
    geth --exec "timestamps=[]; for(i = 0; i < eth.blockNumber; i++) {\
                timestamps.push(eth.getBlock(i).timestamp); }; timestamps; " \
                attach ipc://$IPC_PATH >> test/final_timestamps-$ID.txt
    
    geth --exec "eth.pendingTransactions.length" attach ipc://$IPC_PATH >> test/pendingTransactions-$ID.txt
    
    # Do other useful stuffs, e.g. upload stats to central server and so on
    # Sends SIGNAL to child/sub processes
    kill -HUP $PID
    trap - SIGUSR1 # clear the trap
    printf "Done ..."
    exit 0
}


# geth --exec "eth.blockNumber; tx_count=0; for(i = 0; i < eth.blockNumber; i++) { tx_count += eth.getBlock(i).transactions.length;}; tx_count" attach http://10.14.67.157:8545 

main() {
    local readonly ID=$1
    local readonly IPC_PATH=$7
    shift # Forget about the first argument
    local GETH_ARGS="$@"

    geth $GETH_ARGS &
    
    local readonly PID=$!
    
    trap "catch $ID $IPC_PATH $PID" SIGUSR1
    
    # The parent program should be alive when the signal arrives
    sleep 100000
}

main $ARGS
