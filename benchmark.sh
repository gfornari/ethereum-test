#!/bin/bash
# Dependencies ssh-client, bootnode, geth, lsof, jq

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

readonly BOOTNODE_PORT=29999
readonly IP_ADDRESS=`ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'`
readonly NODES_SETUP_SCRIPT="./nodes_setup.sh"
readonly BENCHMARK_SCRIPT="./benchmark_node.sh"

readonly GIT_REPOSITORY="https://github.com/gfornari/ethereum-test"
readonly REPO_OUTPUT_DIR="./ethereum-test"
# https://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
readonly BRANCH_NAME=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)


main() {
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file> \n" $0
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