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


gather_info() {
    local login_name=$1
    local address=$2
    local result_path=$3 # Path to the result test relative to home dir
    
    mkdir -p test/$address
    scp -r $login_name@$address:$result_path/* test/$address/
}

main() { 
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file>\n" $0
        exit 1;
    fi
    local readonly CONF_FILE=$1
    
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
        
        
        gather_info "$login_name" "$address" "./ethereum-test/test"
        
        start_id=$((start_id+num_client))
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "done.."
    
}

main $ARGS
