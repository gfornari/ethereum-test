import os
import sys
import subprocess
import time

prefix_port = 303
prefix_rpc_port = 81
genesis_block_path = 'genesis_block.json'
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'


def start_nodes(client_number):
	node_ids_string = ""
	for i in range(0, client_number):
		tmp = "%02d " % (i)
		node_ids_string += tmp 
	print(node_ids_string)
	cmd = "parallel python setup_single.py ::: " + node_ids_string
	print (cmd)
	print (cmd.split())
	subprocess.Popen(cmd.split())


def retrieve_enodes(client_number):
	enodes = [0] * client_number
	for i in range(0, client_number):
		rpc_port = "%d%02d " % (prefix_rpc_port, i)
		cmd = "geth --datadir=/tmp/eth/" + str(i) + " attach http://127.0.0.1:" + rpc_port + " --exec admin.nodeInfo.enode"
		enodes[i] = subprocess.check_output(cmd.split( ))
		enodes[i] = enodes[i].decode('ascii').split()[0]
		print(enodes[i])
	return enodes

def add_peers(client_number, enodes):
	for i in range(0, client_number):
		for j in range(0, client_number):
			if i != j:
				rpc_port = "%d%02d " % (prefix_rpc_port, i)
				print(enodes[j])
				cmd = "geth --datadir=/tmp/eth/" + str(i) + " attach http://127.0.0.1:" + rpc_port + " --exec admin.addPeer(" + enodes[j] + ")"
				subprocess.call(cmd.split())
				print(cmd)


#Debug function that checks that the numbers of peers corresponds to 
#the expected one
def check_number_of_peers(client_number):
	for i in range(0, client_number):
		rpc_port = "%d%02d " % (prefix_rpc_port, i)
		cmd = "geth --datadir=/tmp/eth/" + str(i) + " attach http://127.0.0.1:" + rpc_port + " --exec net.peerCount"
		peers = int(subprocess.check_output(cmd.split()).decode('ascii').split()[0])
		if peers != client_number:
			print("Some peers were lost")
			raise



def main(argv):
	if len(sys.argv) < 2:
		print("Usage: python " + sys.argv[0] + " <client_number>")
	else:
		client_number = int(sys.argv[1])
		start_nodes(client_number)
		# TODO: Wait untils services are up and running. sleep should be 
		# only a temporary solution
		sleep_time = 3
		time.sleep(sleep_time)
		print(str(sleep_time) + " seconds elapsed")
		
		#Fetching the enodes of the 
		enodes = retrieve_enodes(client_number)
		add_peers(client_number, enodes)
		check_number_of_peers(client_number)


if __name__ == "__main__":
    main(sys.argv)

