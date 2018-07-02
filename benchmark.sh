#!/bin/bash
# Dependencies ssh-client, bootnode, geth, lsof, jq

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

main() {
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file> [ITERATIONS]\n" $PROGNAME
        exit 1;
    fi

    local readonly CONF_FILE=$1
    local ITERATIONS=5

    if [[ "$#" -gt "1" ]]; then
        ITERATIONS=$2
    fi

    printf "Benchmark with ITERATIONS $ITERATIONS\n"

    # Check if the configuration file exists
    if [[ ! -f "$CONF_FILE" ]]; then
        printf "The configuration file $CONF_FILE does not exists"
        exit 1;
    fi

    # Check if the configuration file is a valid json...
    cat $CONF_FILE | jq "." 2> /dev/null > /dev/null
    if [[ "$?" -ne "0" ]]; then
        printf "The configuration file $CONF_FILE is not a valid json\n"
        exit 1;
    fi

    TEST_DIR=$(jq -r ".test_dir" $CONF_FILE)
    printf "$TEST_DIR"

    rm $TEST_DIR/* -R
    ./gather_test_result.sh $CONF_FILE clean

    for i in $( seq 1 $ITERATIONS ); do
        ./graceful_shutdown.sh $CONF_FILE
        ./setup.sh $CONF_FILE
    done

    # Get new results
    ./gather_test_result.sh $CONF_FILE gather
   
}

main $ARGS