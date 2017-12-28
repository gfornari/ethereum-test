#!/bin/bash

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
    BOOTNODES=$5
    KEYSTORE="keystore"
    RPCADDR="*"
    RPCCORSDOMAIN="127.0.0.1"
    RPCAPI="eth,web3,miner,net,admin,personal"

    JS_SCRIPT_PATH=$6
    OUTPUT_FILE=$7

    nohup geth \
        --datadir $DATADIR \
        --keystore $KEYSTORE \
        --ipcdisable \
        --port $PORT \
        --rpc \
        --rpcport $RPCPORT \
        --rpcaddr $RPCADDR \
        --rpccorsdomain $RPCCORSDOMAIN \
        --rpcapi $RPCAPI \
        --networkid $NETWORKID \
        --bootnodes $BOOTNODES \
        js "$JS_SCRIPT_PATH" \
        >> $OUTPUT_FILE 2>&1
}

# check arguments
if [ $# -lt 3 ]; then
    printf "Usage: `basename "$0"` <nodes-amount> <first-node-index> <bootnodes>\n"
    exit 1
fi

NODES_AMOUNT=$1
FIRST_NODE_INDEX=$2
BOOTNODES=$3

BASE_DATADIR="/tmp/ethtest-datadir-"
OUTPUT_DIR="logs"
JS_SCRIPTS_DIR="js-scripts"

# check if output dir already exists
check_dir $OUTPUT_DIR

# check if js scripts dir already exists
check_dir $JS_SCRIPTS_DIR

# init and start the geth nodes
for node in $(seq 0 $(($NODES_AMOUNT - 1))); do
    printf "Configuring node $node ...\n"

    # build datadir and output file string
    DATADIR=$BASE_DATADIR$node
    OUTPUT_FILE="$OUTPUT_DIR/node-$node.out"
    JS_SCRIPT_PATH="$JS_SCRIPTS_DIR/node-$node.js"

    # remove eventual preexisting directory
    rm -rf $DATADIR

    # init genesis block
    init_genesis $DATADIR $OUTPUT_FILE

    # start geth node in background
    NETWORKID=$(read_chainid)
    PORT=$((30300 + $node))
    RPCPORT=$((8100 + $node))

    printf "conf = {};
        conf.accountIndex = $(($FIRST_NODE_INDEX + $node));
        conf.txDelay = 1000;
        " | cat - sendTransactions.js > $JS_SCRIPT_PATH

    start_node_bg \
        $DATADIR \
        $NETWORKID \
        $PORT \
        $RPCPORT \
        $BOOTNODES \
        $JS_SCRIPT_PATH \
        $OUTPUT_FILE
    printf "Node started. Output in $OUTPUT_FILE\n"
done
