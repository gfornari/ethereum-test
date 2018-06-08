#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


catch() {
    local readonly ID=$1
    local readonly IPC_PATH=$2

    printf "Dump metrics to metrics.txt\n"
    mkdir -p test
    # geth --exec "debug.metrics(true)" attach ipc:$1 > test/metrics.txt
    geth --exec "eth.blockNumber" attach ipc://$IPC_PATH > test/block_number-$ID.txt
    geth --exec "tx_count=0; \
                for(i = 0; i < eth.blockNumber; i++) { \
                tx_count += eth.getBlock(i).transactions.length;}; \
                tx_count;" \
                attach ipc://$IPC_PATH > transactions-$ID.txt
    
    # Do other useful stuffs, e.g. upload stats to central server and so on
    # Sends SIGNAL to child/sub processes
    pkill -HUP geth
    pkill cpu_mem_info.sh
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

    

    printf "$ID \n $IPC_PATH\n"

    trap "catch $ID $IPC_PATH" SIGUSR1

    
    geth $GETH_ARGS &
    
    local readonly pid=$!
    
    chmod +x cpu_mem_info.sh
    
    rm "test/cpu.csv"
    
    touch "test/cpu.csv"
    
    ./cpu_mem_info.sh "$pid" "test/cpu.csv"
    
    sleep 100000
}

main $ARGS
