#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


catch() {
    printf "Dump metrics to metrics.txt\n"
    mkdir -p test
    geth --exec "debug.metrics(true)" attach http://$1:$2 > test/metrics.txt
    geth --exec "eth.blockNumber" attach http://$1:$2 > test/eth.txt
    geth --exec "tx_count=0; \
                for(i = 0; i < eth.blockNumber; i++) { \
                tx_count += eth.getBlock(i).transactions.length;}; \
                tx_count" \
                attach http://$1:$2 >> eth.txt
    
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
    trap "catch ${12} ${10}" SIGUSR1
    geth $ARGS &
    
    pid=$!
    
    chmod +x cpu_mem_info.sh
    
    rm "test/cpu.csv"
    
    touch "test/cpu.csv"
    
    ./cpu_mem_info.sh "$pid" "test/cpu.csv"
    
    sleep 100000
}

main $ARGS
