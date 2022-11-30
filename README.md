# Ephemeral testnets scripts

Tooling for participating in [Ephemeral testnet](https://github.com/taxmeifyoucan/ephemeral-testnet) based on its [genesis repository](https://github.com/pk910/test-testnet-repo). 

Running a node in this test network requires resetting clients with a new genesis after given period. In this repository, you can find scripts and deployment for this automatized setup. 

## Retention script

Script `retention.sh` provides the main mechanism for resetting the network. It checks for period timeout and resets the node automatically. Make sure to read the script first, modify variables and paths to match your setup. 

By default, the script is controlling clients using their systemd services. You can find examples files for services in `systemd-services` directory, you should also modify them to suit your system.

## Automatic deployment 

### Cloud-init

This repository also includes configuration files for `cloud-init`. These provide many deployment options for various client combinations and also explorers. 

### Docker

Another deployment option is using `docker-compose` setup. This is a simple option to run a node which always follows the current chain. 

Just ensure that [Docker](https://docs.docker.com/engine/install/) and [docker-compose](https://docs.docker.com/compose/install/linux/) are installed, clone this repository and start the setup. 

```
git clone https://github.com/pk910/test-testnet-scripts.git
cd test-testnet-scripts/Docker
docker-compose up
```
Currently it only includes single client pair with automatic restart and needs more work. Feel free to extend it with other options. 

## Manual deployment

You can manually run a node by following these instructions.

Warning: you will need to manually reset your system when the testnet is reset.

### Prerequisites

[Install golang](https://go.dev/doc/install) for your system.

Then:
```
sudo apt install -y git default-jre make gcc
```

### Download config

```
mkdir testnet-all
cd testnet-all
```

Download the `testnet-all.tar.gz` file for the [latest release of the Ephemery testnet](https://github.com/pk910/test-testnet-repo/releases) to this directory using `wget`. Then unzip inside this folder.
```
tar -xzf testnet-all.tar.gz
```

### Execution Layer

Download and build software:
```
cd ~
git clone https://github.com/ethereum/go-ethereum.git
cd go-ethereum
make geth
```
Initialise:
```
cd ~
./go-ethereum/build/bin/geth init --datadir "datadir-geth" ~/testnet-all/genesis.json
```
Run:
```
./go-ethereum/build/bin/geth \
     --networkid {networkID} \
     --syncmode=full \
     --port 30303 \
     --datadir "datadir-geth" \
     --http \
     --authrpc.jwtsecret=/tmp/jwtsecret \
     --bootnodes {bootnodes}
```

