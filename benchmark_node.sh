#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

start_benchmark() {
    DATADIR=$1
    NETWORKID=$2
    PORT=$3
    RPCPORT=$4
    RPCADDR=$5
    BOOTNODES=$6
    
    
    ETHASH_DIR="$HOME/ethash"
    ETHASH_CACHE_DIR="$ETHASH_DIR/cache"
    ETHASH_DAG_DIR="$ETHASH_DIR/dag"
    
    
    KEYSTORE="keystore"
    RPCCORSDOMAIN="*"
    RPCAPI="eth,web3,miner,net,admin,personal,debug"
    

    JS_SCRIPT_PATH=$7
    OUTPUT_FILE=$8
    ROLE=$9
    TEST_TIMEOUT=${10}
    TX_INTERVAL=${11}
    
    extra_option="" 
    
    if [[ $ROLE = "miner" ]]; then
        extra_option="--mine --minerthreads 1"
    else
        
        extra_option="js $JS_SCRIPT_PATH"
    fi
    extra_option=$(eval echo $extra_option)
    
    echo "$NETWORKID"
    nohup timeout -s SIGUSR1 "$TEST_TIMEOUT" ./geth_with_catch.sh \
         "$DATADIR" \
         "$KEYSTORE" \
         "$PORT" \
         "$RPCPORT" \
         "$RPCADDR" \
         "\"$RPCCORSDOMAIN\"" \
         "$RPCAPI" \
         "$NETWORKID" \
         "$BOOTNODES" \
         "$ETHASH_CACHE_DIR" \
         "$ETHASH_DAG_DIR" \
         "geth.cpu" \
         "$extra_option" \
        >> $OUTPUT_FILE 2>&1 &
    
    ppid=$!
    
    # Let's wait for the spawning of the subprocess
    sleep 0.5
    
    pid=$(ps -o pid= --ppid $ppid)
    
    echo "The PID of the program is $pid"
    
    chmod +x cpu_mem_info.sh
    
    rm "cpu.csv"
    
    touch "cpu.csv"
    
    nohup timeout $TEST_TIMEOUT ./cpu_mem_info.sh "$pid" "cpu.csv" > /dev/null 2>&1 &
    
    
    
    printf "started cpu/mem demon\n"
}
read_chainid() {
    grep -E -o '"chainId"\s*:\s*[0-9]+' conf/genesis_block.json | grep -E -o '[0-9]+'
}


main() { 

    # check arguments
    if [ $# -lt 4 ]; then
        printf "Usage: `basename "$0"` <nodes-amount> <first-node-index> <rcpaddr> <bootnodes>\n"
        exit 1
    fi
    node=0
    ROLE=$1
    FIRST_NODE_INDEX=$2
    RCPADDR=$3
    BOOTNODES=$4
    TIMEOUT_INTERVAL=$5
    TX_INTERVAL=$6

    printf "TIMEOUT_INTERVAL $TIMEOUT_INTERVAL ...\n"

    
    
    BASE_DATADIR="ethtest-datadir-"
    OUTPUT_DIR="logs"
    JS_SCRIPTS_DIR="js-scripts"
    
    DATADIR=$BASE_DATADIR$node
    OUTPUT_FILE="$OUTPUT_DIR/node-$node.out"
    JS_SCRIPT_PATH="$JS_SCRIPTS_DIR/node-$node.js"
  

    # start geth node in background
    NETWORKID=$(read_chainid)
    PORT=$((30300 + $node))
    RPCPORT=$((8545 + $node))

    printf "conf = {};
        conf.accountIndex = $(($FIRST_NODE_INDEX + $node));
        conf.txDelay = $TX_INTERVAL;
        " | cat - sendTransactions.js > "$JS_SCRIPT_PATH"

    start_benchmark \
        "$DATADIR" \
        "$NETWORKID" \
        "$PORT" \
        "$RPCPORT" \
        "$RCPADDR" \
        "$BOOTNODES" \
        "$JS_SCRIPT_PATH" \
        "$OUTPUT_FILE" \
        "$ROLE" \
        "$TIMEOUT_INTERVAL"
    
    printf "Node ($RCPADDR:$RPCPORT) started. Output in $OUTPUT_FILE\n"
}


main $ARGS


