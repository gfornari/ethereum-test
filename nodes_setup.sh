#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

ask_yn() {
    QUESTION=${1}
    EXIT_ANSWER=${2:-Nn}

    read -p "$QUESTION " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[$EXIT_ANSWER]$ ]]; then
        exit 0
    fi
}

check_dir() {
    DIR=$1

    if [ -d "$DIR" ]; then
        ask_yn "Directory $DIR already exists. Continue anyway?"
    else
        mkdir "$DIR"
    fi
}

read_chainid() {
    grep -E -o '"chainId"\s*:\s*[0-9]+' conf/genesis_block.json | grep -E -o '[0-9]+'
}

init_genesis() {
    DATADIR=$1
    OUTPUT_FILE=$2

    geth init --datadir $DATADIR conf/genesis_block.json > $OUTPUT_FILE 2>&1
}

start_node_bg() {
    DATADIR=$1
    NETWORKID=$2
    PORT=$3
    RPCPORT=$4
    RPCADDR=0.0.0.0
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
    

    # Generate the ethash cache (both for miner and verifiers)
    printf "Generating the cache in $ETHASH_CACHE_DIR."
    printf " This may take a while ...\n"
    geth --verbosity=0 makecache 0 "$ETHASH_CACHE_DIR"
    printf "Cache Generated\n"

    
    # Miner should generate also the DAG 
    if [[ $ROLE = "miner" ]]; then
        printf "Generating the dag in $ETHASH_DAG_DIR."
        printf " This may take a while ...\n"
        geth --verbosity=0 makedag 0 "$ETHASH_DAG_DIR"
        printf "Dag generated\n"
    fi

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
    
    
    BASE_DATADIR="ethtest-datadir-"
    OUTPUT_DIR="logs"
    JS_SCRIPTS_DIR="js-scripts"

    # check if output dir already exists
    check_dir $OUTPUT_DIR

    # check if js scripts dir already exists
    check_dir $JS_SCRIPTS_DIR

    
    printf "Configuring node $node ...\n"

    # build datadir and output file string
    DATADIR=$BASE_DATADIR$node
    OUTPUT_FILE="$OUTPUT_DIR/node-setup-$node.out"
    JS_SCRIPT_PATH="$JS_SCRIPTS_DIR/node-$node.js"

    # remove eventual preexisting directory
    rm -rf $DATADIR

    # init genesis block
    init_genesis $DATADIR $OUTPUT_FILE

    # start geth node in background
    NETWORKID=$(read_chainid)
    PORT=$((30300 + $node))
    RPCPORT=$((8545 + $node))

    printf "conf = {};
        conf.accountIndex = $(($FIRST_NODE_INDEX + $node));
        conf.txDelay = 1000;
        " | cat - sendTransactions.js > $JS_SCRIPT_PATH

    start_node_bg \
        "$DATADIR" \
        "$NETWORKID" \
        "$PORT" \
        "$RPCPORT" \
        "$RCPADDR" \
        "$BOOTNODES" \
        "$JS_SCRIPT_PATH" \
        "$OUTPUT_FILE" \
        "$ROLE"
    
    printf "Node ($RCPADDR:$RPCPORT) started. Output in $OUTPUT_FILE\n"
}


main $ARGS

