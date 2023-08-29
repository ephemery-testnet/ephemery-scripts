Instructions for manually setting up a node on Ephemery using Reth and Lighthouse.

### Prerequisites

Install Rust for your system using [rustup](https://rustup.rs/):
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
During the installation process, choose option 1 for default installation.

For clients' dependencies, see [Lighthouse docs](https://lighthouse-book.sigmaprime.io/installation-source.html#dependencies) and [Reth docs](https://paradigmxyz.github.io/reth/installation/source.html#dependencies).

### Download config

```
cd ~
mkdir testnet-all
cd testnet-all
```

Download the `testnet-all.tar.gz` file for the [latest release of the Ephemery testnet](https://github.com/ephemery-testnet/ephemery-genesis/releases) to this directory using `wget`. Then unzip inside this folder:

```
tar -xzf testnet-all.tar.gz
```

### Generate JWT
A JWT secret file should be used to ensure secure communication between the Execution Client (Reth) and the Consensus client (Lighthouse). Use the following commands, according to the [Lighhouse documentation](https://lighthouse-book.sigmaprime.io/run_a_node.html#step-1-create-a-jwt-secret-file), to create a JWT secret in the `/secrets` folder:

```
sudo mkdir -p /secrets
openssl rand -hex 32 | tr -d "\n" | sudo tee /secrets/jwt.hex
```

### Execution Layer

Reth can be built from source and also offers pre-built binaries.

See Reth documentation for installation instructions:

- [Binaries](https://paradigmxyz.github.io/reth/installation/binaries.html)
- [Build from source](https://paradigmxyz.github.io/reth/installation/source.html)


Use the following command to initialize the databaze from the Ephemery genesis file:
```
cd ~
reth init --datadir "datadir-reth" --chain "~/testnet-all/genesis.json"
```

Afterwards, use the following command to run Reth: 

```
    reth node \
    --chain "~/testnet-all/genesis.json" \
    --full \
    --port 30303 \
    --http \
    --datadir "datadir-reth" \
    --authrpc.jwtsecret "/secrets/jwt.hex" \
    --bootnodes {bootnodes}
```

Modify the paths as needed for your own setup.

For `{bootnodes}` look in `~/testnet-all/boot_enode.txt`. Entries must be separated,by,commas and "enclosed in quotes".

Depending on your OS, it may be necessary to add additional flags. Refer to the [Reth docs](https://paradigmxyz.github.io/reth/cli/node.html) for more details.

### Consensus Layer

Lighthouse can be built from source and also offers pre-built binaries.

See Lighthouse documentation for installation instructions:

- [Binaries](https://lighthouse-book.sigmaprime.io/installation-binaries.html)
- [Build from source](https://lighthouse-book.sigmaprime.io/installation-source.html)

Run:
```
lighthouse beacon_node \
    --testnet-dir "testnet-all" \
    --datadir "datadir-lighthouse" \
    --eth1 \
    --execution-jwt "/secrets/jwt.hex" \
    --execution-endpoint http://localhost:8551 \
    --boot-nodes {bootnodes}
```

For `{bootnodes}` look in `~/testnet-all/boot_enr.txt`. Entries must be separated,by,commas and "enclosed in quotes".

### A note on Ephemery environment variables

As an alternative to manually copying and pasting Ephemery variables into the above commands, you can simply source the relevant Ephemery environment variables and load them to the shell session prior to running the clients.
