#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

start_benchmark() {

    local readonly DATADIR=$1
    local readonly NETWORKID=$2
    local readonly PORT=$3
    local readonly IPC_PATH=$4
    local readonly BOOTNODES=$5
    local readonly KEYSTORE="keystore"
    local readonly JS_SCRIPT_PATH=$6
    local readonly OUTPUT_FILE=$7
    local readonly ROLE=$8
    local readonly TEST_TIMEOUT=${9}
    local readonly ETHASH_DIR=${10}
    local readonly ETHASH_CACHE_DIR="$ETHASH_DIR/cache"
    local readonly ETHASH_DAG_DIR="$ETHASH_DIR/dag"


    extra_option="" 
    
    if [[ $ROLE = "miner" ]]; then
        printf "$ROLE is miner..."
        extra_option="--mine --minerthreads 1"
    else
        extra_option="js $JS_SCRIPT_PATH"
    fi
    extra_option=$(eval echo $extra_option)
    
    echo "$NETWORKID"
    nohup timeout -s SIGUSR1 "$TEST_TIMEOUT" ./geth_with_catch.sh \
        --datadir "$DATADIR" \
        --keystore "$KEYSTORE" \
        --ipcpath "$IPC_PATH" \
        --port "$PORT" \
        --networkid "$NETWORKID" \
        --bootnodes "$BOOTNODES" \
        --metrics \
        --ethash.cachedir "$ETHASH_CACHE_DIR" \
        --ethash.dagdir "$ETHASH_DAG_DIR" \
        --cpuprofile "geth.cpu" \
        $extra_option \
        >> $OUTPUT_FILE 2>&1 &
}


read_chainid() {
    grep -E -o '"chainId"\s*:\s*[0-9]+' conf/genesis_block.json | grep -E -o '[0-9]+'
}


main() { 
    # check arguments
    if [ $# -lt 5 ]; then
        printf "Usage: `basename "$0"` <first-node-index> <role_list> <bootnodes> <timeout-interval> <tx-interval>\n"
        exit 1
    fi
    
    local readonly FIRST_NODE_INDEX=$1
    local readonly ROLE_LIST="$2"
    local readonly NODES_AMOUNT=$(echo $ROLE_LIST | jq "length")
    
    local readonly BASE_ETHASH_DIR="$HOME/ethash"
    local readonly BASE_DATADIR="ethtest-datadir-"
    local readonly OUTPUT_DIR="logs"
    local readonly JS_SCRIPTS_DIR="js-scripts"
    local readonly BOOTNODES=$3
    local readonly TIMEOUT_INTERVAL=$4
    local readonly TX_INTERVAL=$5

    # start geth node in background
    NETWORKID=$(read_chainid)

    printf "Let's start $ROLE_LIST $NODES_AMOUNT nodes\n"

    for node in $(seq 0 $(($NODES_AMOUNT - 1))); do
        # build datadir and output file string
        local readonly DATADIR=$BASE_DATADIR$node
        local readonly ETHASH_DIR=$BASE_ETHASH_DIR$node
        local readonly OUTPUT_FILE="$OUTPUT_DIR/node-$node.out"
        local readonly ROLE=$(echo $ROLE_LIST | jq ".[$node]")
        local readonly JS_SCRIPT_PATH="$JS_SCRIPTS_DIR/node-$node.js"
        local readonly IPC_PATH="$HOME/geth-$node.ipc"

        printf "Starting node $node with role $ROLE...\n"
        
        PORT=$((30300 + $node))
    

        printf "conf = {};
            conf.accountIndex = $(($FIRST_NODE_INDEX + $node));
            conf.txDelay = $TX_INTERVAL;
            " | cat - sendTransactions.js > "$JS_SCRIPT_PATH"

        start_benchmark \
            "$DATADIR" \
            "$NETWORKID" \
            "$PORT" \
            "$IPC_PATH" \
            "$BOOTNODES" \
            "$JS_SCRIPT_PATH" \
            "$OUTPUT_FILE" \
            "$ROLE" \
            "$TIMEOUT_INTERVAL" \
            "$ETHASH_DIR"
    
        printf "Node started. Output in $OUTPUT_FILE\n"
    done
}


main $ARGS


