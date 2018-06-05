#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

catch() {
    echo "foo"
    geth --exec "debug.metrics(false)" attach http://$1:$2

    sleep 10
    pkill geth

    # Do other useful stuffs, e.g. upload stats to central server and so on
    exit 0
}





main() {

    trap "catch $5 $4" SIGTERM
    trap "catch $5 $4" SIGINT

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
        --ethash.cachedir "${10}" \
        --ethash.dagdir "${11}" \
        --cpuprofile "${12}" \
        ${13}

}

main $ARGS
