#!/bin/bash

get_github_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

src_link_path=""
src_need_build="no"

src_reset_git() {
  local git_path="$1"
  local git_repo="$2"
  local git_branch="$3"
  src_need_build="no"

  if [ -d "$git_path" ] && [ "$(git -C $git_path config --get remote.origin.url)" != "$git_repo" ]; then
    # repository change - drop & clone again
    rm -rf $git_path
  fi
  if [ -d "$git_path" ]; then
    # fetch all from origin
    git -C $git_path fetch --all
    if [ "$(git -C $git_path branch --show-current)" != "$git_branch" ]; then
      # switch branch
      git -C $git_path checkout $git_branch
      src_need_build="yes"
    fi
    if [ "$(git -C git rev-list HEAD | head -n 1)" != "$(git -C git rev-list origin/$git_branch | head -n 1)" ]; then
      # reset to origin head
      git -C $git_path reset --hard "origin/$git_branch"
      src_need_build="yes"
    fi
  fi
  if [ ! -d "./git" ]; then
    # clone repository
    git clone -b $git_branch $git_repo $git_path
    src_need_build="yes"
  fi
}


# setup functions

setup_golang() {
  # install golang
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p golang
  cd golang

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(wget -qO- https://golang.org/dl/ | grep -oP '\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )
  fi

  if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
    wget "https://golang.org/dl/go${setup_version}.linux-amd64.tar.gz"

    mkdir $setup_version
    cd $setup_version
    link_path="$(pwd)"

    tar xfz ../go${setup_version}.linux-amd64.tar.gz
  else
    link_path="$(pwd)/$setup_version"
  fi


  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/golang" 2> /dev/null
    ln -s "$link_path" "$src_link_path/golang"
    export PATH=$src_link_path/golang/bin:~/go/bin:$PATH
  fi

  cd $base_dir
}

setup_rust() {
  # install rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
  rustup update
}

setup_eth2valtools() {
  # install eth2-val-tools
  go install github.com/protolambda/eth2-val-tools@latest
}

setup_geth() {
  # update geth
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p geth
  cd geth

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(get_github_release ethereum/go-ethereum)
  fi

  src_need_build="no"
  if [ "$setup_version" = "git" ]; then
    src_reset_git "git" "${3:-"https://github.com/ethereum/go-ethereum.git"}" "${2:-master}"
    cd git
    setup_version="git-$(git branch --show-current)-$(git rev-list HEAD | head -n 1 | head -c 10)"
    link_path="$(pwd)/build"
  else
    if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
      wget "https://github.com/ethereum/go-ethereum/archive/refs/tags/${setup_version}.tar.gz"
      mkdir $setup_version
      cd $setup_version
      link_path="$(pwd)"
      tar xfz ../${setup_version}.tar.gz
      cd go-ethereum-*
      src_need_build="yes"
    else
      link_path="$(pwd)/$setup_version"
    fi
  fi
  echo "setup geth: ${setup_version}  (build: ${src_need_build})"

  if [ "$src_need_build" = "yes" ]; then
    make geth
  fi

  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/geth" 2> /dev/null
    ln -s "$link_path" "$src_link_path/geth"
  fi

  cd $base_dir
}

setup_erigon() {
  # update erigon
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p erigon
  cd erigon

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(get_github_release ledgerwatch/erigon)
  fi

  src_need_build="no"
  if [ "$setup_version" = "git" ]; then
    src_reset_git "git" "${3:-"https://github.com/ledgerwatch/erigon.git"}" "${2:-devel}"
    cd git
    setup_version="git-$(git branch --show-current)-$(git rev-list HEAD | head -n 1 | head -c 10)"
    link_path="$(pwd)/build"
  else
    if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
      wget "https://github.com/ledgerwatch/erigon/archive/refs/tags/${setup_version}.tar.gz"
      mkdir $setup_version
      cd $setup_version
      link_path="$(pwd)"
      tar xfz ../${setup_version}.tar.gz
      cd erigon-*
      src_need_build="yes"
    else
      link_path="$(pwd)/$setup_version"
    fi
  fi
  echo "setup erigon: ${setup_version}  (build: ${src_need_build})"

  if [ "$src_need_build" = "yes" ]; then
    make erigon
  fi

  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/erigon" 2> /dev/null
    ln -s "$link_path" "$src_link_path/erigon"
  fi

  cd $base_dir
}

setup_lighthouse() {
  # update lighthouse
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p lighthouse
  cd lighthouse

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(get_github_release sigp/lighthouse)
  fi

  src_need_build="no"
  if [ "$setup_version" = "git" ]; then
    src_reset_git "git" "${3:-"https://github.com/sigp/lighthouse.git"}" "${2:-unstable}"
    cd git
    setup_version="git-$(git branch --show-current)-$(git rev-list HEAD | head -n 1 | head -c 10)"
    link_path="$HOME/.cargo/bin"
  else
    if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
      wget "https://github.com/sigp/lighthouse/releases/download/$setup_version/lighthouse-${setup_version}-x86_64-unknown-linux-gnu-portable.tar.gz"
      mkdir $setup_version
      cd $setup_version
      link_path="$(pwd)"
      tar xfz ../lighthouse-${setup_version}-x86_64-unknown-linux-gnu-portable.tar.gz
      chmod +x ./*
    else
      link_path="$(pwd)/$setup_version"
    fi
  fi
  echo "setup lighthouse: ${setup_version}  (build: ${src_need_build})"

  if [ "$src_need_build" = "yes" ]; then
    make
  fi

  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/lighthouse" 2> /dev/null
    ln -s "$link_path" "$src_link_path/lighthouse"
  fi

  cd $base_dir
}

setup_lodestar() {
  # update lodestar
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p lodestar
  cd lodestar

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(get_github_release chainsafe/lodestar)
  fi

  src_need_build="no"
  if [ "$setup_version" = "git" ]; then
    src_reset_git "git" "${3:-"https://github.com/chainsafe/lodestar.git"}" "${2:-unstable}"
    cd git
    setup_version="git-$(git branch --show-current)-$(git rev-list HEAD | head -n 1 | head -c 10)"
    link_path="$(pwd)"
  else
    if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
      wget "https://github.com/ChainSafe/lodestar/archive/refs/tags/${setup_version}.tar.gz"
      mkdir $setup_version
      cd $setup_version
      link_path="$(pwd)"
      tar xfz ../${setup_version}.tar.gz
      cd lodestar-*
      src_need_build="yes"
    else
      link_path="$(pwd)/$setup_version"
    fi
  fi
  echo "setup lodestar: ${setup_version}  (build: ${src_need_build})"

  if [ "$src_need_build" = "yes" ]; then
    yarn install --ignore-optional
    yarn run build
  fi

  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/lodestar" 2> /dev/null
    ln -s "$link_path" "$src_link_path/lodestar"
  fi

  cd $base_dir
}

setup_teku() {
  # update teku
  local base_dir=$(pwd)
  local link_path=""
  mkdir -p teku
  cd teku

  setup_version="${1:-latest}"
  if [ "$setup_version" = "latest" ]; then
    setup_version=$(get_github_release ConsenSys/teku)
  fi

  src_need_build="no"
  if [ "$setup_version" = "git" ]; then
    src_reset_git "git" "${3:-"https://github.com/ConsenSys/teku.git"}" "${2:-unstable}"
    cd git
    setup_version="git-$(git branch --show-current)-$(git rev-list HEAD | head -n 1 | head -c 10)"
    link_path="$(pwd)/build/install/teku"
  else
    if [ ! -z "$setup_version" ] && [ ! -d "$setup_version" ]; then
      wget https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/$setup_version/teku-$setup_version.tar.gz
      mkdir $setup_version
      cd $setup_version
      link_path="$(pwd)"
      tar xfz ../teku-$setup_version.tar.gz
    else
      link_path="$(pwd)/$setup_version"
    fi
  fi
  echo "setup teku: ${setup_version}  (build: ${src_need_build})"

  if [ "$src_need_build" = "yes" ]; then
    ./gradlew installDist
  fi

  if [ ! -z "$src_link_path" ] && [ ! -z "$link_path" ] && [ -d "$link_path" ]; then
    rm "$src_link_path/teku" 2> /dev/null
    ln -s "$link_path" "$src_link_path/teku"
  fi

  cd $base_dir
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
