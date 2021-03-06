#!/bin/bash

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

ask_yn() {
    local readonly QUESTION=${1}
    local readonly EXIT_ANSWER=${2:-Nn}

    read -p "$QUESTION " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[$EXIT_ANSWER]$ ]]; then
        exit 0
    fi
}

check_dir() {
    local readonly DIR=$1

    if [ -d "$DIR" ]; then
        ask_yn "Directory $DIR already exists. Continue anyway?"
    else
        mkdir "$DIR"
    fi
}


init_genesis() {
    local readonly DATADIR=$1
    local readonly OUTPUT_FILE=$2
    local readonly TIMESTAMP=$3
    local readonly START_DIFFICULTY=$4
    local readonly GENESIS_FILE=$5
    local readonly GAS_LIMIT=$6

    cat $GENESIS_FILE \
    | jq ".timestamp=\"$TIMESTAMP\"" \
    | jq ".difficulty=\"$START_DIFFICULTY\"" \
    | jq ".gasLimit=\"$GAS_LIMIT\"" > /tmp/genesis_block.json


    

    geth --datadir $DATADIR init /tmp/genesis_block.json >> $OUTPUT_FILE 2>&1
}


generate_ethash_structs() {
    local readonly ROLE=$1
    local readonly ETHASH_DIR=$2
    local readonly ETHASH_CACHE_DIR="$ETHASH_DIR/cache"
    local readonly ETHASH_DAG_DIR="$ETHASH_DIR/dag"


    # Generate the ethash cache (both for miner and verifiers)
    printf "Generating the cache in $ETHASH_CACHE_DIR."
    printf " This may take a while ...\n"
    geth makecache 0 "$ETHASH_CACHE_DIR"
    geth makecache 30001 "$ETHASH_CACHE_DIR"
    geth makecache 60001 "$ETHASH_CACHE_DIR"
    printf "Cache Generated\n"

    
    # Miner should generate also the DAG 
    if [[ "$ROLE" = "miner" ]]; then
        printf "Generating the dag in $ETHASH_DAG_DIR."
        printf " This may take a while ...\n"
        geth makedag 0 "$ETHASH_DAG_DIR"
        geth makedag 30001 "$ETHASH_DAG_DIR"
        printf "Dag generated\n"
    fi

}



main() { 

    # check arguments
    if [ $# -lt 6 ]; then
        printf "Usage: `basename "$0"` [cmd] <role_list> <timestamp> <start-difficulty> < genesis_file> <gas limit>\n"
        exit 1
    fi

    local readonly CMD=$1
    if [[ "$CMD" == "ethash" ]]; then
        :
    elif [[ "$CMD" == "genesis" ]]; then
        :
    else
        printf "Command $CMD not found. Only [ethash|genesis] are recognized"
    fi

  
    local readonly ROLE_LIST=$2
    local readonly TIMESTAMP=$3
    local readonly START_DIFFICULTY=$4
    local readonly GENESIS_FILE=$5
    local readonly GAS_LIMIT=$6

    local readonly NODES_AMOUNT=$(echo $ROLE_LIST | jq "length")
    
    local readonly BASE_ETHASH_DIR="$HOME/ethash"
    local readonly BASE_DATADIR="ethtest-datadir-"
    local readonly OUTPUT_DIR="logs"
    local readonly JS_SCRIPTS_DIR="js-scripts"

    # check if output dir already exists
    check_dir $OUTPUT_DIR

    # check if js scripts dir already exists
    check_dir $JS_SCRIPTS_DIR
    
    # get the run
    RUN=0
    while [[ -a $OUTPUT_DIR/node-setup-0-$RUN.out ]];
    do
        RUN=$((RUN+1))
    done

    for node in $(seq 0 $(($NODES_AMOUNT - 1))); do
        # build datadir and output file string
        local readonly DATADIR=$BASE_DATADIR$node
        local readonly ETHASH_DIR=$BASE_ETHASH_DIR$node
        local readonly OUTPUT_FILE="$OUTPUT_DIR/node-setup-$node-$RUN.out"
        local readonly ROLE=$(echo $ROLE_LIST | jq -r ".[$node]")

        printf "Configuring node $node with role $ROLE...\n"

        

        # remove eventual preexisting directory
        rm -rf $DATADIR
        rm -rf $OUTPUT_FILE

        if [[ "$CMD" == "genesis" ]]; then
            # init genesis block
            init_genesis $DATADIR $OUTPUT_FILE $TIMESTAMP $START_DIFFICULTY $GENESIS_FILE $GAS_LIMIT
        elif [[ "$CMD" == "ethash" ]]; then
            generate_ethash_structs \
                $ROLE \
                $ETHASH_DIR >> $OUTPUT_FILE
        fi
    done
        
    # end for each
}


main $ARGS

