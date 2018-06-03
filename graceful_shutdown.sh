#!/bin/bash


# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

readonly IP_ADDRESS=`ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'`

#
# Given the configuration information of a single machine stop **ALL**
# geth instances that are running on the particular computer
#
stop_machine() {
    local login_name=$1
    local address=$2
    if [[ "$address" == "127.0.0.1" ]] || [[ "$address" == "localhost" ]] || [[ "$address" == "$IP_ADDRESS" ]]; then
        killall -s SIGKILL geth
        pkill -f ./cpu_mem_info.sh
    else
        ssh "$login_name@$address" killall -s SIGKILL geth
        ssh "$login_name@$address" killall -f ./cpu_mem_info.sh
    fi
   

}

stop_bootnode() {
    kill -INT $(pgrep bootnode)
}

main() { 
    if [[ "$#" -lt "1" ]]; then
        printf "Usage %s <conf-file>\n" $0
        exit 1;
    fi

    local readonly CONF_FILE=$1
    
    stop_bootnode

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
        num_client=$(jq -r ".client_number" $tmp_file)
        if [[ "$address" == "$IP_ADDRESS" ]]; then
            address="127.0.0.1"
        fi
        
        stop_machine "$login_name" "$address"
        
        start_id=$((start_id+num_client))
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "done.."
}

main $ARGS
