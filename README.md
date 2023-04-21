# Ephemeral testnets scripts

Tooling for participating in [Ephemeral testnet](https://github.com/ephemery-testnet/ephemery-resources) based on its [genesis repository](https://github.com/ephemery-testnet/ephemery-genesis). 

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

### Kubernetes helm charts

Currently only a geth-lighthouse client pair is supported and retention is not automated.

To deploy a geth-lighthouse node via helm use the [chart](./charts/geth-lighthouse/) included in this repository. More information is available in the included [README.md](./charts/geth-lighthouse/README.md). In order to manually reset the network, follow these steps:

1. Uninstall the chart: `helm uninstall geth-lighthouse-node` 
2. Identify the PersistentVolumeClaim used by the chart: `kubectl get pvc`
3. Delete the pvc, e.g. `kubectl delete pvc geth-lighthouse-node-0`.
4. Install the chart with the latest iteration by setting the value `--set ephemery.iteration=<latest-iteration>`: 


## Manual deployment

If you simply want to run a node on Ephemery, you can manually set this up by following one of the sets of instructions below.

Warning: you will need to manually reset your system when the testnet is reset.

- [geth + teku](./manual/setup-geku.md)