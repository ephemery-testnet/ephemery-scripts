#!/bin/bash

get_github_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

setup_golang() {
  # update golang
  mkdir -p golang
  cd golang
  golang_release=$(wget -qO- https://golang.org/dl/ | grep -oP '\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )
  if [ ! -z "$golang_release" ] && [ ! -d "$golang_release" ]; then
    wget "https://golang.org/dl/go${golang_release}.linux-amd64.tar.gz"

    mkdir $golang_release
    cd $golang_release
    golang_path=$(pwd)

    tar xfz ../go${golang_release}.linux-amd64.tar.gz

    rm ~/golang
    ln -s $golang_path/go ~/golang

    cd ..
  fi
  cd ..
}

setup_eth2valtools() {
  # install eth2-val-tools
  go install github.com/protolambda/eth2-val-tools@latest
}

setup_geth() {
  # update geth
  mkdir -p geth
  cd geth
  geth_release=$(get_github_release ethereum/go-ethereum)
  echo "geth release: ${geth_release}"
  if [ ! -z "$geth_release" ] && [ ! -d "$geth_release" ]; then
    wget "https://github.com/ethereum/go-ethereum/archive/refs/tags/${geth_release}.tar.gz"

    mkdir $geth_release
    cd $geth_release
    tar xfz ../${geth_release}.tar.gz
    cd go-ethereum-*
    geth_path=$(pwd)

    make geth

    rm ~/geth
    ln -s $geth_path/build ~/geth

    cd ..
    cd ..
  fi
  cd ..
}

setup_erigon() {
  # update erigon
  mkdir -p erigon
  cd erigon
  erigon_release=$(get_github_release ledgerwatch/erigon)
  echo "erigon release: ${erigon_release}"
  if [ ! -z "$erigon_release" ] && [ ! -d "$erigon_release" ]; then
    erigon_version=$(echo $erigon_release | sed 's/^v//')
    wget "https://github.com/ledgerwatch/erigon/archive/refs/tags/${erigon_release}.tar.gz"

    mkdir $erigon_release
    cd $erigon_release
    tar xfz ../${erigon_release}.tar.gz
    cd erigon-*
    erigon_path=$(pwd)

    make erigon

    rm ~/erigon
    ln -s $erigon_path/build ~/erigon
    cd ..
  fi
  cd ..
}

setup_lighthouse() {
  # update lighthouse
  mkdir -p lighthouse
  cd lighthouse
  lighthouse_release=$(get_github_release sigp/lighthouse)
  echo "lighthouse release: ${lighthouse_release}"
  if [ ! -z "$lighthouse_release" ] && [ ! -d "$lighthouse_release" ]; then
    wget "https://github.com/sigp/lighthouse/releases/download/$lighthouse_release/lighthouse-${lighthouse_release}-x86_64-unknown-linux-gnu-portable.tar.gz"
    mkdir $lighthouse_release
    cd $lighthouse_release
    lighthouse_path=$(pwd)

    tar xfz ../lighthouse-${lighthouse_release}-x86_64-unknown-linux-gnu-portable.tar.gz
    chmod +x ./*
    rm ~/lighthouse 2> /dev/null
    ln -s $lighthouse_path ~/lighthouse
    cd ..
  fi
  cd ..
}

setup_lodestar() {
  # update lodestar
  mkdir -p lodestar
  cd lodestar
  lodestar_release=$(get_github_release chainsafe/lodestar)
  echo "lodestar release: ${lodestar_release}"
  if [ ! -z "$lodestar_release" ] && [ ! -d "$lodestar_release" ]; then
    wget "https://github.com/ChainSafe/lodestar/archive/refs/tags/${lodestar_release}.tar.gz"
    mkdir $lodestar_release
    cd $lodestar_release
    tar xfz ../${lodestar_release}.tar.gz
    cd lodestar-*
    lodestar_path=$(pwd)

    yarn install --ignore-optional
    yarn run build
    
    rm ~/lodestar 2> /dev/null
    ln -s $lodestar_path ~/lodestar
    cd ..
    cd ..
  fi
  cd ..
}

setup_teku() {
  # update teku
  mkdir -p teku
  cd teku
  teku_release=$(get_github_release ConsenSys/teku)
  echo "teku release: ${teku_release}"
  if [ ! -z "$teku_release" ] && [ ! -d "$teku_release" ]; then
    wget https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/$teku_release/teku-$teku_release.tar.gz
    mkdir $teku_release
    cd $teku_release
    teku_path=$(pwd)

    tar xfz ../teku-$teku_release.tar.gz
    
    rm ~/teku 2> /dev/null
    ln -s $teku_path/teku-$teku_release ~/teku
    cd ..
  fi
  cd ..
}

setup_jwtsecret() {
  # create jwtsecret if not found
  if ! [ -f $1 ]; then
    echo -n 0x$(openssl rand -hex 32 | tr -d "\n") > $1
  fi
}

setup_graffiti_daemon() {
  # update graffiti-daemon
  mkdir -p graffiti-daemon
  cd graffiti-daemon
  gd_release=$(get_github_release pk910/graffiti-daemon)
  echo "graffiti-daemon release: ${gd_release}"
  if [ ! -z "$gd_release" ] && [ ! -d "$gd_release" ]; then
    mkdir $gd_release
    cd $gd_release
    gd_path=$(pwd)

    wget https://github.com/pk910/graffiti-daemon/releases/download/$gd_release/graffiti-daemon-amd64
    chmod +x graffiti-daemon-amd64
    
    rm ~/graffiti-daemon 2> /dev/null
    ln -s $gd_path ~/graffiti-daemon
    cd ..
  fi
  cd ..
}
