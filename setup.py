import os
import sys
import subprocess
import time
import json 
from functools import reduce

prefix_port = 303
prefix_rpc_port = 81
genesis_block_path = 'genesis_block.json'
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'

def start_nodes(conf):
	for host in range(0, len(conf["nodes"])):
		client_number = conf["nodes"][host]["client_number"]
		if client_number > 0:
			node_ids_string = ""
			for i in range(0, client_number):
				tmp = "%02d " % (i)
				node_ids_string += tmp
			cmd = "parallel python setup_single.py ::: " + \
			node_ids_string + " ::: " + conf["nodes"][host]["login_name"] + "@" + \
			conf["nodes"][host]["address"] + " ::: " + conf["my_ip"] + " "
			subprocess.Popen(cmd.split())


def retrieve_enodes(conf):
	all_enodes = {}
	l = len(conf["nodes"])
	print("there are " + str(l) + " hosts")
	for host in range(0, l):
		client_number = conf["nodes"][host]["client_number"]
		if client_number > 0:
			enodes = [0] * client_number
			for i in range(0, client_number):
				rpc_port = "%d%02d " % (prefix_rpc_port, i)
				cmd = "geth  attach http://" + conf["nodes"][host]["address"] + ":" + rpc_port + " --exec admin.nodeInfo.enode"
				enodes[i] = subprocess.check_output(cmd.split( ))
				enodes[i] = enodes[i].decode('ascii').split()[0].replace("[::]", conf["nodes"][host]["address"])
				# ~ print(enodes[i])
			all_enodes[str(host)] = enodes
			# ~ print(all_enodes)
	return all_enodes

def add_peers(conf, enodes):
	print("Add_peers")
	l = len(conf["nodes"])
	for host in range(0, l):
		client_number = conf["nodes"][host]["client_number"]
		if client_number > 0 :
			for other_host in range(0, l):
				other_client_number = conf["nodes"][other_host]["client_number"]
				if other_client_number > 0:
					for i in range(0, client_number):
						for j in range(0, other_client_number):
								if not (i == j and host == other_host):
									rpc_port = "%d%02d " % (prefix_rpc_port, i)
									cmd = "geth attach http://" + conf["nodes"][host]["address"] + ":" + rpc_port + " --exec admin.addPeer(" + enodes[str(other_host)][j] + ")"
									subprocess.call(cmd.split())


#Debug function that checks that the numbers of peers corresponds to 
#the expected one
def check_number_of_peers(conf):
	total_peers = reduce(lambda x, y: x+y["client_number"], conf["nodes"], 0)
	print(total_peers)
	l = len(conf["nodes"])
	for host in range(0, l):
		client_number = conf["nodes"][host]["client_number"]
		for i in range(0, client_number):
			rpc_port = "%d%02d " % (prefix_rpc_port, i)
			cmd = "geth attach http://" + conf["nodes"][host]["address"] + ":" + rpc_port + " --exec net.peerCount"
			peers = int(subprocess.check_output(cmd.split()).decode('ascii').split()[0])
			if peers != (total_peers - 1):
				print("Node %d: found %d peers. Some peers were lost.." % (i, peers))
				raise





def main(argv):
	if len(sys.argv) < 2:
		print("Usage: python " + sys.argv[0] + " <conf-file>")
	else:
		
		conf = json.loads(subprocess.check_output((" cat " + sys.argv[1]).split()).decode('ascii'))
		start_nodes(conf)
		
		# TODO: Wait untils services are up and running. sleep should be 
		# only a temporary solution
		sleep_time = 10
		time.sleep(sleep_time)
		print(str(sleep_time) + " seconds elapsed")
		
		# Fetching the enodes of the 
		enodes = retrieve_enodes(conf)
		
		# Add peers "manually" avoiding discovery
		add_peers(conf, enodes)
		
		check_number_of_peers(conf)
		
		print("Setup successful..")

if __name__ == "__main__":
    main(sys.argv)

