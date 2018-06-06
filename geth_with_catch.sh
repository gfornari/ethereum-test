#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

catch() {
    printf "Dump metrics to metrics.txt\n"
    printf "RPC: http://$1:$2\n"
    
    geth --exec "debug.metrics(false)" attach http://$1:$2 > metrics.txt
    # Do other useful stuffs, e.g. upload stats to central server and so on
    trap - SIGUSR1 # clear the trap
    # Sends SIGNAL to child/sub processes
    pkill geth
    printf "Done ..."
    exit 0
}

main() {
    trap "catch ${12} ${10}" SIGUSR1
    echo $ARGS
    (trap "" SIGUSR1; geth $ARGS &)
    sleep 100000
}

main $ARGS
