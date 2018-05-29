# ethereum-test

This series of scripts allow you to start a new ethereum private ethereum network.

## Getting Started

```sh 
git clone https://github.com/gfornari/ethereum-test.git
cd ethereum-test
```

### Prerequisites

Currently we are supporting only linux. Apart from linux and its bash you need also the following softwares:
   - [geth](https://github.com/ethereum/go-ethereum) - the go ethereum client, which in turn depends on the go language
   - [jq](https://github.com/stedolan/jq) - a command-line JSON processor
   - git - to download the current version of the script in the remote machine
   - sshd - the ssh daemon, needed to log in the remote machines.
   
Otherwise if you have either ubuntu or arch, you can run the installer script
   

```sh
sudo ./installer.sh
```

## Usage

In the conf directory you can find a pre-defined configuration file to deploy your network on your local machine

```sh
./setup.sh <conf-file>
```

To close gracefully the network you can simply reuse the configuration file:

```sh
./graceful-shutdown <conf-file>
```



## Contributing

Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.




## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


## Authors

* **Mirko Bez** - *Initial work* - [herrBez](https://github.com/herrBez)
* **Giacomo Fornari** - *Initial work* - [gfornari](https://github.com/gfornari)


