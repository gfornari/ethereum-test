# ethereum-test

Ethereum test allows creating an Ethereum Private Network using the go ethereum client.

## Getting Started

```sh
   git clone https://github.com/gfornari/ethereum-test.git
   git checkout master
```

### Prerequisites

Currently, the system is tested only on ubuntu. To install the necessary dependendencies use the [installer script installer_ubuntu.sh](installer_ubuntu.sh)

## Running the tests

To setup a network you need a configuration file

```json
{
    "timeout": "50",
    "tx_interval": "1000",
    "test_dir": "./test/",
    "start_difficulty": 240000,
    "bootnode": "enode://...",
    "nodes": 
    [
        {
            "address": "<external-ip>",
            "internal_address": "<internal-ip>",
            "login_name": "<username>",
            "role": "client"
        },
        {
            "address": "<external-ip>",
            "login_name": "<internal-ip>",
            "internal_address":"<username>",
            "role": "miner"
        }
    ]
}
```

## Deployment

```./benchmark.sh conf/conf.json 1```

## Contributing

Any contribution is much appreciated ;)

## Authors

* **Mirko Bez** - *Initial work* - [herrBez](https://github.com/herrBez)
* **Giacomo Fornari** - *Initial work* - [gfornari](https://github.com/gfornari)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details


