#!/bin/bash
# Dependencies ssh-client, bootnode, geth, lsof, jq

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

main() {
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file> \n" $PROGNAME
        exit 1;
    fi

    local readonly CONF_FILE=$1
    local readonly ITERATIONS=5

    # Check if the configuration file is a valid json...
    cat $CONF_FILE | jq "." 2> /dev/null > /dev/null
    if [[ "$?" -ne "0" ]]; then
        printf "The configuration file $CONF_FILE is not a valid json\n"
        exit 1;
    fi

    # Remove old results ...
    rm test/* -R
    ./gather_test_result.sh $CONF_FILE clean

    for i in $( seq 1 $ITERATIONS ); do
        ./setup.sh $CONF_FILE
    done

    # Get new results
    ./gather_test_result.sh $CONF_FILE gather
}

main $ARGS