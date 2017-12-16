import os
import subprocess
import time
import sys

prefix_port = 3030
prefix_rpc_port = 810
genesis_block_path = 'genesis_block.json'
genesis_block_url = 'http://genesisblock.altervista.org/genesis_block.json'



def main(argv):
	
	i = int(argv[1])
	print ("node " + str(i))
	cmd1 = "wget " + genesis_block_url + " -O " + genesis_block_path
	
	# Create the blockchain
	cmd2 = 'geth --datadir=/tmp/eth/' + str(i) + ' init ' + genesis_block_path + " 2>> /dev/null "
	# ~ print(cmd2)
	
	
	cmd3 = 'geth --datadir=/tmp/eth/' + str(i) + ' --ipcdisable ' + \
	'--port ' + str(prefix_port) + str(i) + ' --rpcport ' + \
	str(prefix_rpc_port) + str(i) + ' --rpc --rpccorsdomain 127.0.0.1 --rpcapi eth,web3,miner,net,admin' +\
	' --networkid=11691524842890 --nodiscover console'
	cmd = (cmd1 + " ; " + cmd2 + " ; " + cmd3)
	print(cmd)
	# TODO: Find a portable way to open a new terminal, for now we have
	# to comment/uncomment the following lines depending on the used
	# terminal
	# Konsole
	os.system("konsole --new-tab -e bash -c '" + cmd + "'  ");
	# Ubuntu
	# os.system("gnome-terminal --tab -x bash -c '" + cmd + "' --"); 
	

if __name__ == "__main__":
    main(sys.argv)

