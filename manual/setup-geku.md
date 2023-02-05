Instructions for manually setting up a node on Ephemery using geth and teku.

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

Download and build software:
```
cd ~
git clone https://github.com/ConsenSys/teku.git
cd teku
./gradlew installDist
```
Run:
```
./teku/build/install/teku/bin/teku \
    --network ~/testnet-all/config.yaml \
    --initial-state ~/testnet-all/genesis.ssz \
    --data-path "datadir-teku" \
    --ee-endpoint http://localhost:8551 \
    --ee-jwt-secret-file "/tmp/jwtsecret" \
    --log-destination console \
    --p2p-discovery-bootnodes {bootnodes}
```

For `{bootnodes}` look in ~/testnet-all/boot_enr.txt. Entries must be separated,by,commas and "enclosed in quotes".
