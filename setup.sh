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

#
# Given the configuration information of a single machine executes the
# script on the machine passing the right arguments
#
start_benchmark() {
    
    
    
    local login_name=$1
    local address=$2
    local role=$3
    local start_id=$4
    local bootnode_address=$5
    local internal_address=$6
    local timeout_interval=$7
    local tx_interval=$8

    
    
    
    printf "\n\nstart machine $login_name@$address\n"
    
    
    
    if [[ "$address" == "$IP_ADDRESS" || "$address" == "127.0.0.1" ]]; then
        "$BENCHMARK_SCRIPT" "$role" "$start_id" "$internal_address" "$bootnode_address" "$timeout_interval" "$tx_interval"
        echo $cmd | bash -s 
    else
       
        cmd="\
        cd $REPO_OUTPUT_DIR;\
        chmod +x $BENCHMARK_SCRIPT;\
        $BENCHMARK_SCRIPT $role $start_id $internal_address $bootnode_address $timeout_interval $tx_interval"
       
        echo $cmd | ssh "$login_name@$address" "bash -s"
    fi

}

setup_machine() {
    local login_name=$1
    local address=$2
    local role_list=$3

    cmd="\
    if ! [[ -d \"$REPO_OUTPUT_DIR\" ]]; then\
        git clone $GIT_REPOSITORY $REPO_OUTPUT_DIR;\
    fi;\
    cd $REPO_OUTPUT_DIR;\
    git checkout $BRANCH_NAME;\
    git pull;\
    $NODES_SETUP_SCRIPT \"$role_list\";"
    
    
    
    if [[ "$address" == "$IP_ADDRESS" || "$address" == "127.0.0.1" ]]; then
        printf "local\n\n\n"
        cmd="git checkout $BRANCH_NAME;\
        $NODES_SETUP_SCRIPT \"$role_list\";"
        echo $cmd | bash -s 
    else
        echo $cmd | ssh "$login_name@$address" "bash -s"
    fi

}


#
# Start bootnode
#
#
start_bootnode() {
    bootnode --genkey=boot.key 
    local readonly BOOTNODE_PUB_KEY=$(bootnode --nodekey=boot.key --writeaddress)
    local readonly ENODE_ADDRESS="enode://$BOOTNODE_PUB_KEY@$IP_ADDRESS:$BOOTNODE_PORT"
        
    bootnode --nodekey=boot.key --addr ":$BOOTNODE_PORT" 1> /dev/null 2> /dev/null &
    # Wait until bootnode is up and running
    lsof -i :$BOOTNODE_PORT 1> /dev/null 2> /dev/null
    while [ "$?" != "0" ]; do
        sleep 1
        lsof -i :$BOOTNODE_PORT 1> /dev/null 2> /dev/null
    done
    #~ printf "bootnode is up and running..\n" 
    echo $ENODE_ADDRESS
}


main() { 
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file>\n" $0
        exit 1;
    fi

    local readonly CONF_FILE=$1
    # local readonly ENODE_ADDRESS=$(start_bootnode)
    local readonly ENODE_ADDRESS=$(jq ".bootnode" $CONF_FILE)
    local readonly RAW_TIMEOUT_BENCHMARK=$(jq -r ".timeout" $CONF_FILE)
    local readonly TIMEOUT_BENCHMARK="${RAW_TIMEOUT_BENCHMARK}s"
    local readonly TX_INTERVAL=$(jq -r ".tx_interval" $CONF_FILE)
    

    printf "The bootnode address is: $ENODE_ADDRESS ...\n"

    #
    # Configure all the machines
    #
    #FOR_EACH COMPUTER IN TEST_CONF
    local COMPUTER_ID=0
    local START_NODE_ID=0
    local COMPUTER=""
    while [ true ]; do
        COMPUTER=$(jq -r ".nodes[$COMPUTER_ID]" $CONF_FILE)
        if [ "$COMPUTER" == "null" ]; then
            break;
        fi
        tmp_file=/tmp/tmp.json
        
        echo $COMPUTER > $tmp_file
        local readonly login_name=$(jq -r ".login_name" $tmp_file)
        local readonly address=$(jq -r ".address" $tmp_file)
        # Compact output, get rid of spaces!
        local readonly role_list=$(jq -r -c ".roles" $tmp_file)
       
        setup_machine "$login_name" "$address" "$role_list"
        
        COMPUTER_ID=$((COMPUTER_ID+1))
    done
    #END FOR_EACH

    printf "Setup done ..\n"
    
    #
    # Start the benchmark
    #
    printf "Starting benchmark ..."
    #FOR_EACH COMPUTER IN TEST_CONF
    local COMPUTER_ID=0
    local START_NODE_ID=0
    local COMPUTER=""
    while [ true ]; do
        COMPUTER=$(jq -r ".nodes[$COMPUTER_ID]" $CONF_FILE)
        if [ "$COMPUTER" == "null" ]; then
            break;
        fi
        tmp_file=/tmp/tmp.json
        echo $COMPUTER > $tmp_file
        local readonly login_name=$(jq -r ".login_name" $tmp_file)
        local readonly address=$(jq -r ".address" $tmp_file)
        local readonly role_list=$(jq -r ".roles" $tmp_file)
        
        start_benchmark "$login_name" "$address" "$role_list" "$START_NODE_ID" "$ENODE_ADDRESS" "$internal_address" "$TIMEOUT_BENCHMARK" "$TX_INTERVAL"
        
        start_id=$((start_id+num_client))
        
        COMPUTER_ID=$((COMPUTER_ID+1))
    done
    #END FOR_EACH

    echo "Benchmark started.."
    
    TIMEOUT_BENCHMARK_SLEEP=$((RAW_TIMEOUT_BENCHMARK+30))
    
    printf "Wait $TIMEOUT_BENCHMARK_SLEEP seconds, to collect results\n"

    
    sleep $TIMEOUT_BENCHMARK_SLEEP
    
    printf "Collect results\n"
    
    
    ./gather_test_result.sh $CONF_FILE
}

main $ARGS
