# geth-lighthouse

![Version: 0.1.2](https://img.shields.io/badge/Version-0.1.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Helm chart that spins up a post-merge ethereum node consisting of the go-ethereum (geth) execution client and the lighthouse consensus client.

## Source Code

* <https://github.com/ethereum/go-ethereum>
* <https://github.com/sigp/lighthouse>

## Quick Start

```bash
# install from local copy
helm install geth-lighthouse-node charts/geth-lighthouse
```

NOTE: Service of type NodePort is used by default since otherwise consensus and execution clients will not get an internet-accessible port for
P2P traffic. When deploying multiple nodes, set the p2p ports accordingly and ensure that there is no port conflict, e.g.:

```bash
helm install geth-lighthouse-node-1 charts/geth-lighthouse --set geth.ports.p2p=30304 --set lighthouse.ports.p2p=30104
```

## ephemery

The ephemeral testnet can be enabled with the following flag: `--set global.network=ephemery`.
The current iteration is shown on the [project website](https://ephemery.dev/).

NOTE: Since the ephemeral testnet is small, the requested storage size can be reduced: `--set global.persistence.size=10Gi`

The testnet rolls back to genesis every two days. Rollback is automated via a CronJob that checks every hour if there is a new release.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| InitContainer.image.pullPolicy | string | `"IfNotPresent"` | Container pull policy |
| InitContainer.image.repository | string | `"archlinux"` | Container image repository. Archlinux contains curl and openssl. |
| InitContainer.image.tag | string | `"base-20221211.0.109768"` | Image tag |
| InitContainer.name | string | `"init-container"` | Init container to set the correct permissions to access data directories.  |
| ephemery.image.pullPolicy | string | `"IfNotPresent"` | Container pull policy |
| ephemery.image.repository | string | `"nixery.dev/shell/gnutar/gzip/curl/jq/kubectl/gawk"` | Nixery.dev image |
| ephemery.image.tag | string | `"latest"` | Image tag |
| ephemery.name | string | `"ephemery-init"` | Name of the ephemery container |
| ephemery.repository | string | `"ephemery-testnet/ephemery-genesis"` | Specify ephemery github repository |
| fullnameOverride | string | `""` | Overrides the chart's computed fullname |
| geth.image.pullPolicy | string | `"IfNotPresent"` | Container pull policy |
| geth.image.repository | string | `"ethereum/client-go"` | Container image repository |
| geth.image.tag | string | `"v1.11.6"` | Image tag |
| geth.jsonRpcInterface | string | `"0.0.0.0"` | Specify the listen address of the JSON-RPC API server for the execution client. |
| geth.livenessProbe.initialDelaySeconds | int | `60` |  |
| geth.livenessProbe.periodSeconds | int | `120` |  |
| geth.livenessProbe.tcpSocket.port | int | `8545` | Liveness probe tcpSocket port, default is the geth JSON-RPC port |
| geth.name | string | `"geth"` | Name of the container |
| geth.ports.httpJsonRpc | int | `8545` | [Execution-API](https://github.com/ethereum/execution-apis) port |
| geth.ports.metrics | int | `6060` |  |
| geth.ports.p2p | int | `30303` | TCP and UDP P2P port: place in range 30000-32767 and verify that no existing nodes use these ports |
| geth.readinessProbe.initialDelaySeconds | int | `60` |  |
| geth.readinessProbe.periodSeconds | int | `10` |  |
| geth.readinessProbe.tcpSocket.port | int | `8545` | Readiness probe tcpSocket port, default is the geth JSON-RPC port |
| geth.resources | object | `{}` | Resource requests and limits |
| geth.serviceMonitor.interval | string | `"30s"` |  |
| geth.serviceMonitor.path | string | `"/debug/metrics/prometheus"` |  |
| geth.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| global.affinity | object | `{}` |  |
| global.containerSecurityContext | object | `{}` |  |
| global.engineRpcPort | int | `8551` | Engine API JSON-RPC Port, see also the official [Engine Specification](https://github.com/ethereum/execution-apis/blob/main/src/engine/specification.md) |
| global.imagePullSecrets | object | `{}` | A list of pull secrets is used when credentials are needed to access a container registry with username and password. |
| global.network | string | `"mainnet"` | Ethereum default network. Example: mainnet, goerli, ephemery |
| global.nodeSelector | object | `{}` |  |
| global.persistence | object | `{"accessModes":["ReadWriteOnce"],"size":"2000Gi","storageClassName":null}` | PVC settings  |
| global.persistence.accessModes | list | `["ReadWriteOnce"]` | Access mode for the volume claim template |
| global.persistence.size | string | `"2000Gi"` | Requested size for volume claim template. When using OpenEBS Local PV Device this ensures that a block device with sufficient storage is selected. |
| global.persistence.storageClassName | string | `nil` | Use a specific storage class. |
| global.podAnnotations | object | `{}` |  |
| global.securityContext | object | `{"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001}` | Security Context |
| global.service.annotations | object | `{}` | Service annotations, e.g. for metallb: metallb.universe.tf/loadBalancerIPs: 10.1.2.3 |
| global.service.type | string | `"ClusterIP"` | Service type, ClusterIP or LoadBalancer |
| global.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| global.serviceAccount.create | bool | `true` | Enable service account (Note: Service Account will only be automatically created if `global.serviceAccount.name` is not set) |
| global.serviceAccount.name | string | `""` | Name of an already existing service account. Setting this value disables the automatic service account creation |
| global.serviceMonitor.create | bool | `false` |  |
| global.terminationGracePeriodSeconds | int | `300` |  |
| global.tolerations | list | `[]` |  |
| global.updateStrategy.type | string | `"RollingUpdate"` | Update stategy type |
| lighthouse.checkpointSync.enabled | bool | `false` |  |
| lighthouse.checkpointSync.url | string | `"https://beaconstate.info"` |  |
| lighthouse.extBuilder.enabled | bool | `true` | enable external builder (mev-boost) |
| lighthouse.extBuilder.url | string | `"http://mev-boost:18500"` | url of external builder |
| lighthouse.httpRestInterface | string | `"0.0.0.0"` | Specify the listen address of the lighthouse REST API server for the consensus client. |
| lighthouse.image.pullPolicy | string | `"IfNotPresent"` |  |
| lighthouse.image.repository | string | `"sigp/lighthouse"` | Container image repository |
| lighthouse.image.tag | string | `"v4.1.0"` | Image tag |
| lighthouse.livenessProbe.initialDelaySeconds | int | `60` |  |
| lighthouse.livenessProbe.periodSeconds | int | `120` |  |
| lighthouse.livenessProbe.tcpSocket.port | int | `5052` | Liveness probe tcpSocket port, default is the lighthouse httpRest port. |
| lighthouse.name | string | `"lighthouse"` | Name of the container |
| lighthouse.ports.httpRest | int | `5052` | [Beacon-API](https://ethereum.github.io/beacon-APIs/) port |
| lighthouse.ports.metrics | int | `5054` |  |
| lighthouse.ports.p2p | int | `30103` | TCP and UDP P2P port: place in range 30000-32767 and verify that no existing nodes use these ports |
| lighthouse.readinessProbe.initialDelaySeconds | int | `60` |  |
| lighthouse.readinessProbe.periodSeconds | int | `10` |  |
| lighthouse.readinessProbe.tcpSocket.port | int | `5052` | Readiness probe tcpSocket port, default is the lighthouse httpRest port. |
| lighthouse.resources | object | `{}` | Resource requests and limits |
| lighthouse.serviceMonitor.interval | string | `"30s"` |  |
| lighthouse.serviceMonitor.path | string | `"/metrics"` |  |
| lighthouse.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| nameOverride | string | `""` | Overrides the chart's name |