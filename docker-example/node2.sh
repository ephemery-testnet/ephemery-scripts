#!/bin/bash

# general options
node_name="node2" # docker container prefix
node_user="node2" # run as username
node_uid="$(id -u $node_user)"
extip="135.181.231.117" # public ip of the node

# images
el_image="pk910/ephemery-geth:latest"
bn_image="pk910/ephemery-lighthouse:latest"
vc_image="pk910/ephemery-lighthouse:latest"

# datadirs
el_datadir="/data/node2/execution"
bn_datadir="/data/node2/beacon"
vc_datadir="/data/node2/validator"
jwtsecret_file="/data/node2/jwtsecret"

# ports
el_p2p_port=30303
el_rpc_port=8545
el_engine_port=8551
el_metrics_port=9001
bn_p2p_port=9000
bn_rpc_port=5052
bn_metrics_port=5054
vc_metrics_port=5055
port_offset=0  # increase all ports by this offset

# misc
fee_recipient="0x14627ea0e2B27b817DbfF94c3dA383bB73F8C30b"
graffiti="pk910 (2)"



# start / stop scripts

start_el() {
  ensure_datadir $el_datadir
  p2p_port=$(expr $el_p2p_port + $port_offset)
  rpc_port=$(expr $el_rpc_port + $port_offset)
  engine_port=$(expr $el_engine_port + $port_offset)
  metrics_port=$(expr $el_metrics_port + $port_offset)
  ensure_jwtsecret

  # geth
  docker run -d --restart unless-stopped --name=$node_name-el \
    --pull always \
    -u $node_uid \
    -v $jwtsecret_file:/execution-auth.jwt:ro \
    -v $el_datadir:/data \
    -p $p2p_port:$p2p_port \
    -p $p2p_port:$p2p_port/udp \
    -p $rpc_port:$rpc_port \
    -p $engine_port:$engine_port \
    -p $metrics_port:$metrics_port \
    -it $el_image \
    --datadir=/data --port=$p2p_port \
    --http --http.addr=0.0.0.0 --http.port=$rpc_port \
    --http.vhosts=* --http.api=eth,net,web3,txpool,personal,debug \
    --authrpc.addr=0.0.0.0 --authrpc.port=$engine_port --authrpc.vhosts=* \
    --authrpc.jwtsecret=/execution-auth.jwt \
    --nat=extip:$extip \
    --metrics --metrics.addr=0.0.0.0 --metrics.port=$metrics_port \
    --syncmode=full
}

start_bn() {
  ensure_datadir $bn_datadir
  p2p_port=$(expr $bn_p2p_port + $port_offset)
  rpc_port=$(expr $bn_rpc_port + $port_offset)
  engine_port=$(expr $el_engine_port + $port_offset)
  metrics_port=$(expr $bn_metrics_port + $port_offset)
  ensure_jwtsecret

  # lighthouse bn
  docker run -d --restart unless-stopped --name=$node_name-bn \
    --pull always \
    -u $node_uid \
    -v $jwtsecret_file:/execution-auth.jwt:ro \
    -v $bn_datadir:/data \
    -p $p2p_port:$p2p_port \
    -p $p2p_port:$p2p_port/udp \
    -p $rpc_port:$rpc_port \
    -p $metrics_port:$metrics_port \
    -it $bn_image \
    lighthouse beacon_node \
    --datadir=/data \
    --disable-upnp --disable-enr-auto-update --enr-address=$extip \
    --port=$p2p_port --discovery-port=$p2p_port --enr-tcp-port=$p2p_port --enr-udp-port=$p2p_port \
    --listen-address=0.0.0.0 \
    --http --http-address=0.0.0.0 --http-port=$rpc_port \
    --execution-endpoint=http://172.17.0.1:$engine_port --execution-jwt=/execution-auth.jwt \
    --metrics --metrics-allow-origin=* --metrics-address=0.0.0.0 --metrics-port=$metrics_port
}

start_vc() {
  ensure_datadir $vc_datadir
  rpc_port=$(expr $bn_rpc_port + $port_offset)
  metrics_port=$(expr $vc_metrics_port + $port_offset)

  # lighthouse vc
  docker run -d --restart unless-stopped --name=$node_name-vc \
    --pull always \
    -u $node_uid \
    -v $vc_datadir:/data \
    -p $metrics_port:$metrics_port \
    -it $vc_image \
    lighthouse validator_client \
    --validators-dir=/data/keys \
    --secrets-dir=/data/secrets \
    --init-slashing-protection \
    --beacon-nodes=http://172.17.0.1:$rpc_port \
    --metrics --metrics-allow-origin=* --metrics-address=0.0.0.0 --metrics-port=$metrics_port \
    --graffiti $graffiti --suggested-fee-recipient $fee_recipient
}

copy_vc_keys() {
  ensure_datadir $vc_datadir
  keystores=$1
  if [ -f $vc_datadir/keys ]; then
    rm -rf $vc_datadir/keys
  fi
  if [ -f $vc_datadir/secrets ]; then
    rm -rf $vc_datadir/secrets
  fi

  cp $keystores/keys -r $vc_datadir/keys
  cp $keystores/secrets -r $vc_datadir/secrets
  chown -R $node_user $vc_datadir/keys $vc_datadir/secrets
}

stop_el() {
  docker rm -f $node_name-el
}

stop_bn() {
  docker rm -f $node_name-bn
}

stop_vc() {
  docker rm -f $node_name-vc
}

ensure_jwtsecret() {
  if ! [ -f $jwtsecret_file ]; then
    jwtsecret_path=$(dirname $jwtsecret_file)
    if ! [ -f $jwtsecret_path ]; then
      mkdir -p $jwtsecret_path
    fi
    echo -n 0x$(openssl rand -hex 32 | tr -d "\n") > $jwtsecret_file
    chown $node_user $jwtsecret_file
  fi
}

ensure_datadir() {
  if ! [ -f $1 ]; then
    mkdir -p $1
    chown $node_user $1
  fi
}

reset_vc_keys() {
  count="$1"
  mnemonic="${@:2}"
  if [ -z "$count" ]; then
    echo "key-count argument missing. run with ./node.sh reset-vc-keys <key-count> <mnemonic>"
    exit 1
  fi
  if [ -z "$mnemonic" ]; then
    echo "mnemonic argument missing. run with ./node.sh reset-vc-keys <key-count> <mnemonic>"
    exit 1
  fi

  tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'keys')
  docker run --rm -v $tmpdir:/data -it protolambda/eth2-val-tools:latest keystores --out-loc /data/keystores --source-mnemonic "$mnemonic" --source-min 0 --source-max $count
  copy_vc_keys $tmpdir/keystores
  rm -rf $tmpdir
}

if ! [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  case "$1" in
   start-el) start_el ;;
   stop-el) stop_el ;;
   start-bn) start_bn ;;
   stop-bn) stop_bn ;;
   start-vc) start_vc ;;
   stop-vc) stop_vc ;;
   reset-vc-keys) reset_vc_keys $2 "${@:3}" ;;
   *)
     echo "Usage $0 {start-el|stop-el|start-bn|stop-bn|start-vc|stop-vc|reset-vc-keys}"
    ;;
  esac
fi
