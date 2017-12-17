import os
import subprocess
import time
import sys
import errno
import json


prefix_port = 303
prefix_rpc_port = 81
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'




def download_genesis_block(genesis_block_path):
	cmd1 = "wget " + genesis_block_url + " -O " + genesis_block_path
	subprocess.call(cmd1.split())

def initialize_blockchain(data_dir, genesis_block_path):
	# Command to initialize the the blockchain with the genesis_block
	cmd2 = 'geth --datadir=' + data_dir + ' init ' + genesis_block_path + " 2>> /dev/null "
	subprocess.call(cmd2.split())

def start_node(data_dir, port, rpc_port, network_id, rpcaddr, rpccorsdomain):
	# Command to start a geth client that uses our test blockchain
	cmd3 = 'geth --datadir=' + data_dir + ' --ipcdisable ' + \
	'--port ' + port + ' --rpcport ' + \
	rpc_port + ' --rpc --rpcaddr ' + rpcaddr + ' --rpccorsdomain ' + rpccorsdomain + ' --rpcapi eth,web3,miner,net,admin' +\
	' --networkid=' + str(network_id) + '  --nodiscover'
	subprocess.Popen(cmd3.split())


def main(argv):
	rpcaddr = "127.0.0.1"
	rpccorsdomain = "127.0.0.1"
	if len(argv) < 2:
		print("Usage: python %s <node_id> [rpc_addr] [allowed_rpc_client_ip]" % (argv[0]))
	else:
		i = int(argv[1])
		if len(argv) > 2:
			rpcaddr = argv[2]
		if len(argv) > 3:
			rpccorsdomain = argv[3]
		
		print ("node " + str(i))
		
		
		port = "%d%02d" % (prefix_port, i)
		rpc_port = "%d%02d" % (prefix_rpc_port, i)
		data_dir = "/tmp/eth/" + str(i)
		tmp_data_dir = "/tmp/foo/" + str(i)
		genesis_block_path = 'genesis_block.json'
		genesis_block_path = tmp_data_dir + "/" + genesis_block_path
		try:
			os.makedirs(data_dir)
			os.makedirs(tmp_data_dir)
		except OSError as e:
			if e.errno != errno.EEXIST:
				raise  # raises the error again
		
		
		download_genesis_block(genesis_block_path)
		
		initialize_blockchain(data_dir, genesis_block_path)
		
		genesis_block = json.load(open(genesis_block_path))
		network_id=genesis_block["config"]["chainId"]
		
		start_node(data_dir, port, rpc_port, network_id, rpcaddr, rpccorsdomain)
		
		# TODO: Find a portable way to open a new terminal, for now we have
		# to comment/uncomment the following lines depending on the used
		# terminal
		# Konsole
		#os.system("konsole --new-tab -e bash -c '" + cmd + "'  ");
		# Ubuntu
		# os.system("gnome-terminal --tab -x bash -c '" + cmd + "' --"); 
	

if __name__ == "__main__":
    main(sys.argv)

