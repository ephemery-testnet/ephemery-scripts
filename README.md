# Ephemeral testnets scripts

Tooling for participating in [Ephemeral testnet](https://github.com/ephemery-testnet/ephemery-resources) based on its [genesis repository](https://github.com/ephemery-testnet/ephemery-genesis). 

Running a node in this test network requires resetting clients with a new genesis after given period. In this repository, you can find scripts and deployment for this automatized setup. 

## Retention script

Script `retention.sh` provides the main mechanism for resetting the network. It checks for period timeout and resets the node automatically. Configure your script using a file containing the following environment variables, and pass that file as the first argument to `retention.sh`.

- TESTNET_DIR - Path to the directory in which Ephemery testnet files are stored
- EL_CLIENT - Type of execution client, lower case: geth, nethermind, besu, erigon, or reth
- EL_SERVICE - Name of the execution client systemd service to start/stop
- EL_DATADIR - Data directory of the execution client
- CL_CLIENT - Type of consensus client, lower case: prysm, lighthouse, nimbus, teku or lodestar
- CL_SERVICE - Name of the consensus client systemd service to start/stop
- CL_DATADIR - Data directory of consensus client
- CL_PORT - JSON RPC port of consensus client. Default: `3500`
- VC_CLIENT - **Optional:** Type of validator client, lower case: prysm, lighthouse, nimbus, teku or lodestar. Leave unset if using single-process consensus/validator client.
- VC_SERVICE - **Optional:** Name of the validator client systemd service to start/stop. Leave unset if using single-process consensus/validator client.
- VC_DATADIR - **Optional:** Data directory of validator client. Leave unset if using single-process consensus/validator client.
- EPHEMERY_FILES_USER - **Optional:** User to which Ephemery testnet directory and files should be assigned. By default file ownership will be left unchanged.
- EPHEMERY_FILES_GROUP - **Optional:** Group to which Ephemery testnet directory and files should be assigned. By default the group will be left unchanged.
- FORCE_RESET - **Optional:** Set to `1` to force reset of testnet files and clients for testing purposes. Default: `0`

See `.env.sample` for an example of setting the environment variables. Run `retention.sh .env` to use values set in `.env` environment variables file.

Default values for all environment variables may also be set within the script and the script can be run as `retention.sh`.

By default, the script is controlling clients using their systemd services. You can find examples files for services in `systemd-services` directory, you should also modify them to suit your system.

## Automatic deployment 

### Cloud-init

This repository also includes configuration files for `cloud-init`. These provide many deployment options for various client combinations and also explorers. 

### Docker compose

Another deployment option is using `docker-compose` setup. This is a simple option to run a node which always follows the current chain. 

Just ensure that [Docker](https://docs.docker.com/engine/install/) and [docker-compose](https://docs.docker.com/compose/install/linux/) are installed, clone this repository and start the setup. 

```
git clone https://github.com/pk910/test-testnet-scripts.git
cd test-testnet-scripts/docker-compose
docker-compose up
```
Currently it only includes single client pair with automatic restart and needs more work. Feel free to extend it with other options. 

### Docker images (with ephemery wrapper)

There are automatically build customized client images for all major ethereum clients available via the [ephemery-client-wrapper](https://github.com/pk910/ephemery-client-wrapper) repository.

The repository takes the original client images and injects a wrapper script that takes care of the ephemery related things (reset mechanism & client flags). The images are meant to be drop-in replacements for the official images, so they should be fully compatible with any setup that uses the official client images.

See the list of client images & example docker commands in the [README.md](https://github.com/pk910/ephemery-client-wrapper/blob/main/README.md#clients).
You can also take a look into the example scripts in [docker-example](./docker-example)

### Kubernetes helm charts

For deployments to a kubernetes cluster, you can find an example helm chart in the [charts](./charts) folder.

Currently only the geth-lighthouse client pair is supported, retention is automated via a Kubernetes CronJob.

More information on how to deploy the chart and it's default values can be found in [README.md](./charts/geth-lighthouse/README.md).

## Manual deployment

If you simply want to run a node on Ephemery, you can manually set this up by following one of the sets of instructions below.

Warning: you will need to manually reset your system when the testnet is reset.

- [geth + teku](./manual/setup-geku.md)
- [geth + lodestar](./manual/setup-geth-lodestar.md)
- [reth + lighthouse](./manual/setup-reth-lighthouse.md)
