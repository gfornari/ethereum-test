#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

catch() {
    printf "Dump metrics to metrics.txt\n"
    
    geth --exec "debug.metrics(true)" attach http://$1:$2 > metrics.txt
    geth --exec "eth.blockNumber; \
                tx_count=0; \
                for(i = 0; i < eth.blockNumber; i++) {
                    tx_count += eth.getBlock(i).transactions.length;
                }" attach http://$1:$2 > eth.txt
    # Do other useful stuffs, e.g. upload stats to central server and so on
    trap - SIGUSR1 # clear the trap
    # Sends SIGNAL to child/sub processes
    pkill geth
    pkill cpu_mem_info.sh
    printf "Done ..."
    exit 0
}

main() {
    trap "catch ${12} ${10}" SIGUSR1
    geth $ARGS &
    
    pid=$!
    
    chmod +x cpu_mem_info.sh
    
    rm "cpu.csv"
    
    touch "cpu.csv"
    
    ./cpu_mem_info.sh "$pid" "cpu.csv"
    
    sleep 100000
}

main $ARGS
