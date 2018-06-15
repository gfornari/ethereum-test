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
    
    
    
    local readonly login_name=$1
    local readonly address=$2
    local readonly role_list=$3
    local readonly start_id=$4
    local readonly bootnode_address=$5
    local readonly internal_address=$6
    local readonly timeout_interval=$7
    local readonly tx_interval=$8

    
    
    
    printf "\n\nstart machine $login_name@$address\n"
    
    
    cmd="\
    cd $REPO_OUTPUT_DIR;\
    chmod +x $BENCHMARK_SCRIPT;\
    $BENCHMARK_SCRIPT '$role_list' $start_id $internal_address $bootnode_address $timeout_interval $tx_interval"
    
    echo $cmd | ssh "$login_name@$address" "bash -s"

}

setup_machine() {
    local readonly login_name=$1
    local readonly address=$2
    local readonly role_list=$3
    local readonly timestamp=$4
    local readonly START_DIFFICULTY=$5

    # cmd="\
    # if ! [[ -d \"$REPO_OUTPUT_DIR\" ]]; then\
    #    git clone $GIT_REPOSITORY $REPO_OUTPUT_DIR;\
    # fi;\
    # cd $REPO_OUTPUT_DIR;\
    # git checkout $BRANCH_NAME;\
    # git pull;
    
    cmd="rm -rf $REPO_OUTPUT_DIR" 
    echo $cmd | ssh "$login_name@$address" "bash -s"

    # scp -r ./$LOCAL_REPO_DIR/ $login_name@$address:$REPO_OUTPUT_DIR
    rsync -r ./$LOCAL_REPO_DIR/ $login_name@$address:$REPO_OUTPUT_DIR
    
    cmd="cd $REPO_OUTPUT_DIR; \
        $NODES_SETUP_SCRIPT '$role_list' $timestamp $START_DIFFICULTY;"

    echo $cmd | ssh "$login_name@$address" "bash -s"
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

    # Check if the configuration file is a valid json...
    cat $CONF_FILE | jq "." 2> /dev/null > /dev/null
    if [[ "$?" -ne "0" ]]; then
        printf "The configuration file $CONF_FILE is not a valid json\n"
        exit 1;
    fi

    # local readonly ENODE_ADDRESS=$(start_bootnode)
    local readonly ENODE_ADDRESS=$(jq ".bootnode" $CONF_FILE)
    local readonly EXTRA_TIMEOUT=$(jq -r ".extra_timeout" $CONF_FILE)
    local readonly RAW_TIMEOUT_BENCHMARK=$(jq -r ".timeout" $CONF_FILE)
    local readonly TIMEOUT_BENCHMARK="${RAW_TIMEOUT_BENCHMARK}s"
    local readonly TX_INTERVAL=$(jq -r ".tx_interval" $CONF_FILE)
    local readonly START_DIFFICULTY=$(jq -r ".start_difficulty" $CONF_FILE)

    printf "START_DIFFICULTY = $START_DIFFICULTY"
    

    printf "The bootnode address is: $ENODE_ADDRESS ...\n"

    timestamp=$(date +%s)

    local readonly LOCAL_REPO_DIR=$(basename $GIT_REPOSITORY)
    if ! [[ -d \"./$LOCAL_REPO_DIR\" ]]; then\
        git clone $GIT_REPOSITORY;\
    fi;\
    cd ./$LOCAL_REPO_DIR
    git checkout $BRANCH_NAME
    git pull
    cd ..
    
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
        local readonly role_list="$(jq -r -c ".roles" $tmp_file)"
        printf "$role_list"
       
        setup_machine "$login_name" "$address" "$role_list" "$timestamp" "$START_DIFFICULTY"
        
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
        local readonly role_list=$(jq -r -c ".roles" $tmp_file)
        local readonly num_client=$(echo $role_list | jq "length")
        
        start_benchmark \
            "$login_name"\
            "$address" \
            "$role_list" \
            "$START_NODE_ID" \
            "$ENODE_ADDRESS" \
            "$internal_address" \
            "$TIMEOUT_BENCHMARK" \
            "$TX_INTERVAL" \

        
        START_NODE_ID=$((START_NODE_ID+num_client))
        
        COMPUTER_ID=$((COMPUTER_ID+1))
    done
    #END FOR_EACH

    echo "Benchmark started.."
    
    TIMEOUT_BENCHMARK_SLEEP=$((${RAW_TIMEOUT_BENCHMARK}+${EXTRA_TIMEOUT}))
    
    INITIAL_DATE=$(date +"%H:%M:%S")
    EXPECTED_END_DATE=$(date +"%H:%M:%S" -d "$TIMEOUT_BENCHMARK_SLEEP seconds")

    printf "[$INITIAL_DATE]: Wait $TIMEOUT_BENCHMARK_SLEEP seconds, to collect results. "
    printf "Expected Finish date $EXPECTED_END_DATE\n"

    
    sleep $TIMEOUT_BENCHMARK_SLEEP
    
}

main $ARGS
