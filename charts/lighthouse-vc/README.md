# lighthouse-vc

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

Installs lighthouse in validator client mode.

## Source Code

* <https://github.com/ethereum/go-ethereum>
* <https://github.com/sigp/lighthouse>

## Quick Start

```shell
# install from local copy
helm install lighthouse-vc charts/lighthouse-vc
```

To access the beacon API, the api bearer token needs to be retrieved. By default the pod stores it under `/data/api-token.txt`, e.g. :

```bash
kubectl exec lighthouse-vc-0 -- cat /data/api-token.txt
```

Port forward for local development:

```bash
kubectl port-forward svc/lighthouse-vc 5062:5062
# check version
curl localhost:5062/lighthouse/version -H "Authorization: Bearer <enter-bearer-token-here>"
```

## Ephemery

The ephemeral testnet can be enabled with the following flag: `--set global.network=ephemery`.
The current iteration is shown on the [project website](https://ephemery.dev/).

NOTE: Since the ephemeral testnet is small, the requested storage size can be reduced: `--set global.persistence.size=10Gi`

The testnet rollback is automated via a CronJob that checks every five minutes whether there is a new genesis release.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ephemery.image.pullPolicy | string | `"IfNotPresent"` | Container pull policy |
| ephemery.image.repository | string | `"nixery.dev/shell/gnutar/gzip/curl/jq/kubectl/gawk"` | Nixery.dev image |
| ephemery.image.tag | string | `"latest"` | Image tag |
| ephemery.name | string | `"ephemery-init"` | Name of the ephemery container |
| ephemery.repository | string | `"ephemery-testnet/ephemery-genesis"` | Specify ephemery github repository |
| fullnameOverride | string | `""` | Overrides the chart's computed fullname |
| global.affinity | object | `{}` |  |
| global.beaconNodes | list | `["http://geth-lighthouse-node:5052"]` | List of Consenus Client (Beacon Nodes) endpoints available within cluster |
| global.containerSecurityContext | object | `{}` |  |
| global.imagePullSecrets | object | `{}` | A list of pull secrets is used when credentials are needed to access a container registry with username and password. |
| global.network | string | `"mainnet"` | Ethereum default network. Example: mainnet, goerli, ephemery |
| global.nodeSelector | object | `{}` |  |
| global.persistence.accessModes | list | `["ReadWriteOnce"]` | Access mode for the volume claim template |
| global.persistence.size | string | `"2Gi"` | Requested size for volume claim template. When using OpenEBS Local PV Device this ensures that a block device with sufficient storage is selected. |
| global.persistence.storageClassName | string | `nil` | Use a specific storage class. |
| global.podAnnotations | object | `{}` |  |
| global.replicas | int | `1` | Replicas |
| global.securityContext | object | `{"fsGroup":1001,"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001}` | Security Context |
| global.service.annotations | object | `{}` | Service annotations, e.g. for metallb: metallb.universe.tf/loadBalancerIPs: 10.1.2.3 |
| global.service.type | string | `"ClusterIP"` | Service type, ClusterIP or LoadBalancer |
| global.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| global.serviceAccount.create | bool | `true` | Enable service account (Note: Service Account will only be automatically created if `global.serviceAccount.name` is not set) |
| global.serviceAccount.name | string | `""` | Name of an already existing service account. Setting this value disables the automatic service account creation |
| global.serviceMonitor.create | bool | `false` |  |
| global.serviceMonitor.interval | string | `"30s"` |  |
| global.serviceMonitor.path | string | `"/metrics"` |  |
| global.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| global.statefulSetAnnotations | object | `{}` |  |
| global.terminationGracePeriodSeconds | int | `120` |  |
| global.tolerations | list | `[]` |  |
| global.updateStrategy.type | string | `"RollingUpdate"` | Update stategy type |
| lighthouse.feeRecipient | string | `"0xc90E920F4DCfd4954230edCaB168D0C5B9561e03"` |  |
| lighthouse.graffiti | string | `"lighthouse"` |  |
| lighthouse.httpInterface | string | `"0.0.0.0"` | Specify the listen address of the lighthouse REST API server for the consensus client. |
| lighthouse.image.pullPolicy | string | `"IfNotPresent"` |  |
| lighthouse.image.repository | string | `"sigp/lighthouse"` | Container image repository |
| lighthouse.image.tag | string | `"v4.1.0"` | Image tag |
| lighthouse.livenessProbe.httpGet.path | string | `"/lighthouse/auth"` | Path for [VC endpoints](https://lighthouse-book.sigmaprime.io/api-vc-endpoints.html) NOTE: for /lighthouse/health the api token is required. |
| lighthouse.livenessProbe.httpGet.port | int | `5062` | Liveness probe http port, default is the lighthouse httpRest port. |
| lighthouse.livenessProbe.initialDelaySeconds | int | `500` |  |
| lighthouse.livenessProbe.periodSeconds | int | `30` |  |
| lighthouse.name | string | `"lighthouse"` | Name of the container |
| lighthouse.ports.httpJson | int | `5062` | [Validator Client API](https://lighthouse-book.sigmaprime.io/api-vc.html) port |
| lighthouse.ports.metrics | int | `6060` | Metrics ports |
| lighthouse.readinessProbe.httpGet.path | string | `"/lighthouse/auth"` | Path for [VC endpoints](https://lighthouse-book.sigmaprime.io/api-vc-endpoints.html) NOTE: for /lighthouse/health the api token is required. |
| lighthouse.readinessProbe.httpGet.port | int | `5062` | Readiness probe tcpSocket port, default is the lighthouse httpRest port. |
| lighthouse.readinessProbe.initialDelaySeconds | int | `500` |  |
| lighthouse.readinessProbe.periodSeconds | int | `30` |  |
| lighthouse.resources | object | `{}` | Resource requests and limits |
| lighthouse.serviceMonitor.enabled | bool | `false` |  |
| lighthouse.serviceMonitor.interval | string | `"30s"` |  |
| lighthouse.serviceMonitor.path | string | `"/metrics"` |  |
| lighthouse.serviceMonitor.scrapeTimeout | string | `"10s"` |  |
| nameOverride | string | `""` | Overrides the chart's name |