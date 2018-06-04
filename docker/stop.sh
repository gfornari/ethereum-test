
# Constants used along the program
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"


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
        num_client=$(jq -r ".client_number" $tmp_file)
        
        docker swarm leave --force
        
        computer_id=$((computer_id+1))
    done
    #END FOR_EACH

    echo "done.."
}

main $ARGS
