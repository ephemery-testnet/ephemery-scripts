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

### Optional: Generate jwt
If you are generating a jwt (refer to client documentation) the following command will generate a secret to ensure secure communication between the Execution Client and the Consensus client at `/tmp/jwtsecret`. Be mindful that using a jwt may require additional flags to be provided.


```
openssl rand -hex 32 | tr -d "\n" > "/tmp/jwtsecret"
```

### Execution Layer

For Geth you can either download a binary directly, or compile it from the github repository.

If using a binary, ensure to verify it.

Refer to Geth's documentation:

- [Downloads](https://geth.ethereum.org/downloads)

- [Compiling](https://github.com/ethereum/go-ethereum)

To initialise Geth with Ephemery settings, run the following:
```
cd ~
./go-ethereum/build/bin/geth init --datadir "datadir-geth" ~/testnet-all/genesis.json
```

Then, to run Geth:
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

Modify the paths as needed for your own setup.

For `{bootnodes}` look in ~/testnet-all/boot_enode.txt. Entries must be separated,by,commas and "enclosed in quotes".

For `{networkID}` look for `chainId` in ~/testnet-all/genesis.json

Depending on your OS, it may be necessary to add additional flags, for example `—authrpc.addr 0.0.0.0`; refer to the Geth docs for more details.

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

### A note on Ephemery environment variables

As an alternative to manually copying and pasting Ephemery variables into the above commands, you can simply source the Ephemery environment variables and load them to the shell session prior to running the clients, for example:

```
source node_vars.txt 
...
--bootnodes $BOOTNODE_ENR_LIST
```
