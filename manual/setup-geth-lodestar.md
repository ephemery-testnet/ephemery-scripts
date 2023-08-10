Instructions for manually setting up a node on Ephemery using geth and lodestar.

### Prerequisites

[Install golang](https://go.dev/doc/install) for your system.
[Install Yarn](https://classic.yarnpkg.com/lang/en/docs/install/).
Check that your [Node](https://nodejs.org/) version is >= v18.15.0.

Then:
```
sudo apt install -y git default-jre make gcc
```

### Download config

```
mkdir testnet-all
cd testnet-all
```

Download the `testnet-all.tar.gz` file for the [latest release of the Ephemery testnet](https://github.com/ephemery-testnet/ephemery-genesis/releases) to this directory using `wget`. Then unzip inside this folder.
```
tar -xzf testnet-all.tar.gz
```

### Generate jwt

```
openssl rand -hex 32 | tr -d "\n" > "/tmp/jwtsecret"
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
     --http \
     --datadir "datadir-geth" \
     --authrpc.jwtsecret=/tmp/jwtsecret \
     --bootnodes {bootnodes}
```

For `{bootnodes}` look in ~/testnet-all/boot_enode.txt. Entries must be separated,by,commas and "enclosed in quotes".

For `{networkID}` look for `chainId` in ~/testnet-all/genesis.json

### Consensus Layer

Open a new terminal session.

Lodestar doesn’t provide a prebuilt binary, so we must build from source - see their [docs](https://chainsafe.github.io/lodestar/install/source/).  

Download and build software:
```
cd ~
git clone https://github.com/chainsafe/lodestar.git
cd lodestar
yarn
yarn run build
```
Run:
```
./lodestar beacon \
    --dataDir="datadir-lodestar" \
    --paramsFile=~/testnet-all/config.yaml \
    --genesisStateFile=~/testnet-all/genesis.ssz \
    --eth1.depositContractDeployBlock=0 \
    --network.connectToDiscv5Bootnodes=true \
    --discv5=true \
    --eth1=true \
    --eth1.providerUrls=http://localhost:8545 \
    --execution.urls=http://localhost:8551 \
    --bootnodes={BOOTNODE_ENR_LIST} \
    --jwt-secret=/tmp/jwtsecret \
    --rest=true \
    --rest.address=0.0.0.0 \
    --rest.port=4000
```

For `{BOOTNODE_ENR_LIST}` look in ~/testnet-all/nodevars_env.txt.
