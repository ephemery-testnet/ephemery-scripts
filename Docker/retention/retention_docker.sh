#!/bin/bash

genesis_repository="pk910/test-testnet-repo"
testnet_dir="/data/testnet"
el_datadir="/data/geth-data"
cl_datadir="/data/lh-data"
cl_port=5052

start_clients() {
  # start EL / CL clients
  echo "start clients"
  docker start geth
  docker start lighthouse
}

stop_clients() {
  # stop EL / CL clients
  echo "stop clients"
  docker stop geth
  docker stop lighthouse
}

clear_datadirs() {
  if [ -d $el_datadir/geth ]; then
    geth_nodekey=$(cat $el_datadir/geth/nodekey)
    rm -rf $el_datadir/geth
    mkdir $el_datadir/geth
    echo $geth_nodekey > $el_datadir/geth/nodekey
  elif [ -d $el_datadir/chaindata ]; then
    erigon_nodekey=$(cat $el_datadir/nodekey)
    rm -rf $el_datadir/*
    echo $erigon_nodekey > $el_datadir/nodekey
  fi
  rm -rf $cl_datadir/beacon
  rm -rf $cl_datadir/validators/slashing_protection.sqlite
}

setup_genesis() {
  # init el genesis
   docker run -v $hostdir:/data ethereum/client-go:v1.10.26 init --datadir /data/geth-data /data/testnet/genesis.json 
   ID=`cat /data/testnet/nodevars_env.txt | awk -F '"' 'FNR == 2 {print $2}'`
   sed "s/NET_ID/$ID/" /data/geth-conf.example > /data/geth-data/geth-conf.toml
}

get_github_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | jq -r '.tag_name'
}

download_genesis_release() {
  genesis_release=$1

  # remove old genesis
  if [ -d $testnet_dir ]; then
    rm -rf $testnet_dir/*
  else
    mkdir -p $testnet_dir
  fi

  # get latest genesis
  echo "Pulling latest network specs $genesis_release"
  wget -qO- https://github.com/$genesis_repository/releases/download/$genesis_release/testnet-all.tar.gz | tar xvz -C $testnet_dir
  cp $testnet_dir/nodevars_env.txt /data/.env 
  echo copied
}

reset_testnet() {
  stop_clients
  clear_datadirs
  download_genesis_release $1
  setup_genesis
  start_clients
}

check_timeout() {
  current_time=$(date +%s)
  genesis_time=$(curl -s http://localhost:$cl_port/eth/v1/beacon/genesis | jq -r '.data.genesis_time')
  if ! [ $genesis_time -gt 0 ]; then
    echo "could not get genesis time from beacon node"
    return 0
  fi

  if ! [ -f $testnet_dir/retention.vars ]; then
    echo "could not find retention.vars"
    return 0
  fi
  source $testnet_dir/retention.vars

  testnet_timeout=$(expr $genesis_time + $GENESIS_RESET_INTERVAL - 300)
  echo "genesis timeout: $(expr $testnet_timeout - $current_time) sec"
  if [ $testnet_timeout -le $current_time ]; then
    genesis_release=$(get_github_release $genesis_repository)
    if ! [ $ITERATION_RELEASE ]; then
      ITERATION_RELEASE=$CHAIN_ID
    fi
    if [ $genesis_release = $ITERATION_RELEASE ]; then
      echo "could not find new genesis release (release: $genesis_release)"
      return 0
    fi
    reset_testnet $genesis_release
  fi
}

#check if 
check_network() {
  
  el_id=`printf "%d\n" $(curl -s -X POST  localhost:8545 -H "Content-Type: application/json"     --data '{"jsonrpc":"2.0", "method":"eth_chainId", "params":[], "id":1}'  | jq -r '.result')`
  net_id=`cat testnet/genesis.json | jq -r '.config.chainId'`

  cl_time=`curl -s localhost:5052/eth/v1/beacon/genesis | jq -r '.data.genesis_time'`
  net_time=`cat testnet/genesis.json  | jq -r ".timestamp"`

  if ! [ $el_id -eq $net_id ] || ! [[ $cl_time -eq $net_time+300 ]]; then
    reset_testnet $(get_github_release $genesis_repository)
  fi
}

main() {

if ! [ -f $testnet_dir/genesis.json ]; then
  echo "Resetting testnet"
  reset_testnet $(get_github_release $genesis_repository)
fi

sleep 5
check_timeout
check_network

while [ 1 ] 
do
check_timeout
sleep 60
done
}

main

