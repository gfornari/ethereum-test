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
readonly BRANCH_NAME="benchmark"

#
# Given the configuration information of a single machine executes the
# script on the machine passing the right arguments
#
start_benchmark() {
    
    
    
    local login_name=$1
    local address=$2
    local num_client=$3
    local start_id=$4
    local bootnode_address=$5
    
    
    printf "\n\nstart machine $login_name@$address\n"
    
    
    
    if [[ "$address" == "$IP_ADDRESS" ]]; then
        "$BENCHMARK_SCRIPT" "$role" "$start_id" "$address" "$bootnode_address"
        echo $cmd | bash -s 
    else
       
        cmd="\
        cd $REPO_OUTPUT_DIR;\
        chmod +x $BENCHMARK_SCRIPT;\
        $BENCHMARK_SCRIPT $role $start_id $address $bootnode_address"
       
        echo $cmd | ssh "$login_name@$address" "bash -s"
    fi

}

setup_machine() {
    local login_name=$1
    local address=$2
    local num_client=$3
    local start_id=$4
    local bootnode_address=$5

    
    
   
    # This command will: 
    # 1. Check if the repo exists. If it is not the case, it will 
    # clone it.
    # 2. Cd in the right directory checkout in the right directory
    # 3. Checkout the right branch
    # 4. Update the content of the repo
    # 5. Call the NODES_SETUP_SCRIPT
    cmd="\
    if ! [[ -d \"$REPO_OUTPUT_DIR\" ]]; then\
        git clone $GIT_REPOSITORY $REPO_OUTPUT_DIR;\
    fi;\
    cd $REPO_OUTPUT_DIR;\
    git checkout $BRANCH_NAME;\
    git pull;\
    $NODES_SETUP_SCRIPT \"$role\" \"$start_id\" \"$address\" \"$bootnode_address\";"
    
    
    
    if [[ "$address" == "$IP_ADDRESS" ]]; then
        printf "local\n\n\n"
        cmd="git checkout $BRANCH_NAME;\
        $NODES_SETUP_SCRIPT \"$role\" \"$start_id\" \"$address\" \"$bootnode_address\";"
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
    
    printf $ENODE_ADDRESS
    
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
    local readonly ENODE_ADDRESS=$(start_bootnode)
    printf "Started bootnode with address: $ENODE_ADDRESS ...\n"

    #FOR_EACH COMPUTER IN TEST_CONF
    local computer_id=0
    local start_node_id=0
    local computer=""
    while [ true ]; do
        computer=$(jq -r ".nodes[$computer_id]" $CONF_FILE)
        if [ "$computer" == "null" ]; then
            break;
        fi
        tmp_file=/tmp/tmp.json
        echo $computer > $tmp_file
        login_name=$(jq -r ".login_name" $tmp_file)
        address=$(jq -r ".address" $tmp_file)
        role=$(jq -r ".role" $tmp_file)
        
        
        setup_machine "$login_name" "$address" "$role" "$start_node_id" "$ENODE_ADDRESS"
        
        start_id=$((start_id+num_client))
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "Setup done .."
    
    ####
    # Benchmark
    #
    ###
    #FOR_EACH COMPUTER IN TEST_CONF
    local computer_id=0
    local start_node_id=0
    local computer=""
    while [ true ]; do
        computer=$(jq -r ".nodes[$computer_id]" $CONF_FILE)
        if [ "$computer" == "null" ]; then
            break;
        fi
        tmp_file=/tmp/tmp.json
        echo $computer > $tmp_file
        login_name=$(jq -r ".login_name" $tmp_file)
        address=$(jq -r ".address" $tmp_file)
        role=$(jq -r ".role" $tmp_file)
        
        
        start_benchmark "$login_name" "$address" "$role" "$start_node_id" "$ENODE_ADDRESS"
        
        start_id=$((start_id+num_client))
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "done.."
    
}

main $ARGS
