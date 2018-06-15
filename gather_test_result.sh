#!/bin/bash
# Dependencies ssh-client, bootnode, geth, lsof, jq

# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
readonly REPO_OUT_DIR="./ethereum-test"

gather_info() {
    local readonly login_name=$1
    local readonly address=$2
    local readonly result_path=$3 # Path to the result test relative to home dir
    local readonly test_dir=$4
    local readonly role_length=$5
    
    mkdir -p $test_dir/$address
    scp -r $login_name@$address:$result_path/* $test_dir/$address/
    scp -r $login_name@$address:$REPO_OUT_DIR/logs $test_dir/$address

    for ID in $(seq 0 $((role_length-1)));
    do
        ./column_composer.py $test_dir/$address/final_difficulty-$ID-*.txt $test_dir/$address/final_difficulty-$ID.csv
        ./column_composer.py $test_dir/$address/final_timestamps-$ID-*.txt $test_dir/$address/final_timestamps-$ID.csv
    done
    

  

}

remove_old_results() {
    local readonly login_name=$1
    local readonly address=$2
    local readonly result_path=$3
    local readonly test_dir=$4

    rm -rf $test_dir/*
    cmd="rm -rf $result_path/*"
    echo $cmd | ssh "$login_name@$address" "bash -s"
}

main() { 
    if [[ "$#" -lt "2" ]]; then
        printf "Usage %s <conf-file> <clean|gather>\n" $0
        exit 1;
    fi
    local readonly CONF_FILE=$1
    local readonly COMMAND=$2

    local FUNCTION=""
    local MESSAGE=""
    if [[ "$COMMAND" == "clean" ]]; then
        FUNCTION=remove_old_results
    elif [[ "$COMMAND" == "gather" ]]; then
        FUNCTION=gather_info
    else
        printf "The inserted command is not supported"
        exit 1;
    fi
    
    printf "Let's execute $COMMAND\n"

    local readonly TEST_DIR=$(jq -r ".test_dir" $CONF_FILE)

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
        role_length=$(jq -r ".roles" $tmp_file | jq "length")
        
        $FUNCTION "$login_name" "$address" "$REPO_OUT_DIR/test" "$TEST_DIR" "$role_length"
        
        start_id=$((start_id+num_client))
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "done.."
    
}

main $ARGS
