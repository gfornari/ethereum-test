#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

catch() {
    echo "foo"
    geth --exec "debug.metrics(false)" attach http://$1:$2 > metrics.txt

    # Do other useful stuffs, e.g. upload stats to central server and so on
    trap - SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
    exit 0
}

catch_sigint() {
    echo "Maybe something bad happened. Please check if geth is still running"
    trap - SIGINT # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
    exit 1
}




main() {

    trap "catch $5 $4" SIGTERM
    trap "catch_sigint $5 $4" SIGINT

    echo $ARGS

    geth \
        --datadir "$1" \
        --keystore "$2" \
        --ipcdisable \
        --port "$3" \
        --rpc \
        --rpcport "$4" \
        --rpcaddr "$5" \
        --rpccorsdomain "$6" \
        --rpcapi "$7" \
        --networkid "$8" \
        --bootnodes "$9" \
        --metrics \
        --gcmode "archive"
        --ethash.cachedir "${10}" \
        --ethash.dagdir "${11}" \
        ${13}

}

main $ARGS
