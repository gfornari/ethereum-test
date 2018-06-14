#!/usr/bin/python

import json
import sys

def main(argv):
    config = {}
    config["test_time"] = argv[1]
    config["extra_timeout"] = int(argv[2])
    config["tx_interval"] = argv[3]
    config["test_dir"] = argv[4]
    config["start_difficulty"] = int(argv[5])
    config["bootnode"] = argv[6]


    with open(argv[0], "r") as fd:
        ip_address_list = fd.readlines()
        node=[]
        for ip in ip_address_list:
            node.append({"addresses": ip.strip(), "login_name": "scalability", "role":["client"]})
    
    config["nodes"] = node
    with open(argv[6], "w") as out:
        json.dump(config, fp=out, indent=4)

if __name__ == '__main__':    
    
    if len(sys.argv) < 8:
        print("Usage: %s <ip_file> <test-time> <elapsed-time-between-tests> <tx_interval> <test-output-dir> <start_difficulty> <bootnode-enode> <output_file>" % sys.argv[0])
        sys.exit(0)
    main(sys.argv[1:])


