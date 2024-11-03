#!/bin/bash

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if an environment file is provided as the first argument
if [[ -n "$1" ]]; then
  ENV_FILE="$1"
  # Check if the specified environment file exists and source it
  if [[ -f "$ENV_FILE" ]]; then
    log "Loading environment variables from $ENV_FILE"
    source "$ENV_FILE"
  else
    log "Environment file '$ENV_FILE' not found."
    exit 1
  fi
else
  log "No environment file provided. Using default values."
fi

genesis_repository="ephemery-testnet/ephemery-genesis"
timeout_window=600

## Defaults can be set here or use environment variables to override defaults

default_testnet_dir=

# execution
default_el_client=
default_el_service=
default_el_datadir=

# consensus
default_cl_client=
default_cl_service=
default_cl_datadir=
default_cl_port=3500

# validator
default_vc_client=
default_vc_service=
default_vc_datadir=

# Ephemery Ownership
default_ephemery_files_user=
default_ephemery_files_group=

## Read environment variables, if present

testnet_dir=${TESTNET_DIR:-$default_testnet_dir}

el_client=${EL_CLIENT:-$default_el_client}
el_service=${EL_SERVICE:-$default_el_service}
el_datadir=${EL_DATADIR:-$default_el_datadir}

cl_client=${CL_CLIENT:-$default_cl_client}
cl_service=${CL_SERVICE:-$default_cl_service}
cl_datadir=${CL_DATADIR:-$default_cl_datadir}
cl_port=${CL_PORT:-$default_cl_port}

vc_client=${VC_CLIENT:-$default_vc_client}
vc_service=${VC_SERVICE:-$default_vc_service}
vc_datadir=${VC_DATADIR:-$default_vc_datadir}

ephemery_files_user=${EPHEMERY_FILES_USER:-$default_ephemery_files_user}
ephemery_files_group=${EPHEMERY_FILES_GROUP:-$default_ephemery_files_group}

# Set FORCE_RESET environment variable to 1 test reset
force_reset="${FORCE_RESET:-0}"

start_clients() {
  # start clients
  log "Starting $cl_service and $el_service services"
  /bin/systemctl start $cl_service
  /bin/systemctl start $el_service

  if [ -n "$vc_service" ]; then
    log "Starting $vc_service service"
    /bin/systemctl start $vc_service
  fi
}

stop_clients() {
  # stop clients
  log "Stopping $cl_service and $el_service systemd services"
  /bin/systemctl stop $cl_service
  /bin/systemctl stop $el_service

  if [ -n "$vc_service" ]; then
    log "Stopping $vc_service service"
    /bin/systemctl stop $vc_service
  fi
}

clear_execution_datadir() {
  case "$el_client" in
    "geth")
      # Delete everything in $cl_datadir/geth/* except for nodekey
      if [ -d "$el_datadir/geth" ]; then
        find "$el_datadir/geth" -mindepth 1 -maxdepth 1 ! -name 'nodekey' -exec rm -rf {} +
        log "Retained nodekey file in $el_datadir and deleted other contents for $el_client execution client"
      fi
      ;;

    "erigon")
      if [ -d "$el_datadir" ]; then
        find "$el_datadir" ! -name 'config.json' ! -name 'customGenesis.json' -type f -delete
        log "Retained config.json and customGenesis.json files in $el_datadir and deleted other contents for $el_client execution client"
      fi
      ;;

    *)
      if [ -d "$el_datadir" ]; then
        rm -rf "$el_datadir"/*
        log "Deleted contents of $el_datadir/ for $el_client execution client"
      fi
      ;;
  esac
}

clear_consensus_datadir() {
  case "$cl_client" in
    "teku")
      # Delete everything in $cl_datadir/beacon/* except for kvstore
      if [ -d "$cl_datadir/beacon" ]; then
        find "$cl_datadir/beacon" -mindepth 1 -maxdepth 1 ! -name 'kvstore' -exec rm -rf {} +
        log "Retained kvstore file in $cl_datadir/beacon and deleted other contents for $cl_client consensus client"
      fi

      # Delete logs if present
      if [ -d "$cl_datadir/logs" ]; then
        rm -rf "$cl_datadir/logs"/*
        log "Deleted contents of $cl_datadir/logs for $cl_client consensus client"
      fi

      # Delete slashprotection/slashprotection.sqlite if present
      # Captures validator requirements if using single process
      if [ -f "$cl_datadir/slashprotection/slashprotection.sqlite" ]; then
        rm -rf "$cl_datadir/slashprotection/slashprotection.sqlite"
        log "Deleted $cl_datadir/slashprotection/slashprotection.sqlite for $cl_client consensus client"
      fi
      ;;

    "lighthouse")
      # Delete everything in $cl_datadir/beacon/* except for network
      if [ -d "$cl_datadir/beacon" ]; then
        find "$cl_datadir/beacon" -mindepth 1 -maxdepth 1 ! -name 'network' -exec rm -rf {} +
        log "Retained network file in $cl_datadir/beacon and deleted other contents for $cl_client consensus client"
      fi

      # Delete keys/slashing_protection.sqlite
      # Captures validator requirements if using single process
      if [ -f $cl_datadir/keys/slashing_protection.sqlite ]; then
        rm -rf $cl_datadir/keys/slashing_protection.sqlite
        log "Deleted contents of $cl_datadir/keys/slashing_protection.sqlite for $cl_client consensus client"
      fi
      ;;

    "lodestar")
      # Delete chaindb if present
      if [ -d "$cl_datadir/chain-db" ]; then
        rm -rf "$cl_datadir/chain-db"/*
        log "Deleted contents of $cl_datadir/chain-db for $cl_client consensus client"
      fi

      # Delete validator-db directory if present
      # Captures validator requirements if using single process
      if [ -d "$cl_datadir/validator-db" ]; then
        rm -rf "$cl_datadir/validator-db"/*
        log "Deleted contents of $cl_datadir/validator-db for $cl_client consensus client"
      fi
      ;;

    "nimbus")
      rm -rf "$cl_datadir"/*
      log "Deleted contents of $cl_datadir data directory for $cl_client consensus client"

      # Delete validators/slashing_protection.sqlite3
      # Captures validator requirements if using single process
      if [ -f $vc_datadir/validators/slashing_protection.sqlite3 ]; then
        rm -rf $vc_datadir/validators/slashing_protection.sqlite3
        log "Deleted $vc_datadir/validators/slashing_protection.sqlite3 for $cl_client consensus client"
      fi
      ;;

    "prysm")
      rm -rf "$cl_datadir"/*
      log "Deleted contents of $cl_datadir data directory for $cl_client consensus client"

      # Delete prysm-wallet-v2/direct/validator.db
      # Captures validator requirements if using single process
      if [ -f $vc_datadir/prysm-wallet-v2/direct/validator.db ]; then
        rm -rf $vc_datadir/prysm-wallet-v2/direct/validator.db
        log "Deleted $vc_datadir/prysm-wallet-v2/direct/validator.db for $cl_client consensus client"
      fi
      ;;
  esac
}

clear_validator_datadir() {
  if [ -n "$vc_service" ] && [ -n "$vc_client" ] && [ -n "$vc_datadir" ]; then
    case "$vc_client" in
      "prysm")
        if [ -f $vc_datadir/prysm-wallet-v2/direct/validator.db ]; then
          rm -rf $vc_datadir/prysm-wallet-v2/direct/validator.db
          log "Deleted $vc_datadir/prysm-wallet-v2/direct/validator.db for $vc_client validator client"
        fi
        ;;

      "teku")
        if [ -f $vc_datadir/slashprotection/slashprotection.sqlite ]; then
          rm -rf $vc_datadir/slashprotection/slashprotection.sqlite
          log "Deleted $vc_datadir/slashprotection/slashprotection.sqlite for $vc_client validator client"
        fi
        ;;

      "nimbus")
        if [ -f $vc_datadir/validators/slashing_protection.sqlite3 ]; then
          rm -rf $vc_datadir/validators/slashing_protection.sqlite3
          log "Deleted $vc_datadir/validators/slashing_protection.sqlite3 for $vc_client validator client"
        fi
        ;;

      "lighthouse")
        if [ -f $vc_datadir/keys/slashing_protection.sqlite ]; then
          rm -rf $vc_datadir/keys/slashing_protection.sqlite
          log "Deleted $vc_datadir/keys/slashing_protection.sqlite for $vc_client validator client"
        fi
        ;;

      "lodestar")
        # Delete validator-db if present
        if [ -d "$vc_datadir/validator-db" ]; then
          rm -rf "$vc_datadir/validator-db"/*
          log "Deleted contents of $vc_datadir/validator-db/ for $vc_client validator client"
        fi
        ;;
    esac
  fi
}

setup_genesis() {
  case "$el_client" in
    "geth")
      log "Initializing geth genesis"
      geth init --datadir $el_datadir $testnet_dir/genesis.json
      ;;

    "erigon")
      log "Initializing erigon genesis"
      erigon init --datadir $el_datadir $testnet_dir/genesis.json
      ;;
  esac
}

get_github_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    head -n 1
}

download_genesis_release() {
  genesis_release=$1

  # remove old genesis
  if [ -d $testnet_dir ]; then
    rm -rf $testnet_dir/*
    log "Removed existing files from testnet directory $testnet_dir"
  else
    mkdir -p $testnet_dir
    log "Created testnet directory $testnet_dir"
  fi

  # get latest genesis
  log "Getting latest genesis files and unpacking into $testnet_dir"
  wget -qO- https://github.com/$genesis_repository/releases/download/$genesis_release/testnet-all.tar.gz | tar xvz -C $testnet_dir > /dev/null 2>&1

  # Reset ephemery file ownership if we have a username and group
  if [ -n "$ephemery_files_user" ] && [ -n "$ephemery_files_group" ]; then
    chown -R $ephemery_files_user:$ephemery_files_group $testnet_dir
    log "Reset ownership and group of Ephemery genesis files in $testnet_dir to $ephemery_files_user:$ephemery_files_group"
  fi
}

reset_testnet() {
  stop_clients
  clear_consensus_datadir
  clear_execution_datadir
  clear_validator_datadir
  download_genesis_release $1
  setup_genesis
  start_clients
}

check_testnet() {
  current_time=$(date +%s)
  genesis_time=$(curl -s http://127.0.0.1:$cl_port/eth/v1/beacon/genesis | sed 's/.*"genesis_time":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')
  if ! [ $genesis_time -gt 0 ]; then
    log "Could not get genesis time from beacon node"
    return 0
  fi

  if ! [ -f $testnet_dir/retention.vars ]; then
    log "Could not find retention.vars"
    return 0
  fi
  source $testnet_dir/retention.vars

  testnet_timeout=$(expr $genesis_time + $GENESIS_RESET_INTERVAL - $timeout_window)
  log "Genesis timeout: $(expr $testnet_timeout - $current_time) sec (timeout at $(date -d @$testnet_timeout '+%Y-%m-%d %H:%M:%S'))"
  if [ $testnet_timeout -le $current_time ]; then
    genesis_release=$(get_github_release $genesis_repository)
    if ! [ $ITERATION_RELEASE ]; then
      ITERATION_RELEASE=$CHAIN_ID
    fi

    if [ $genesis_release = $ITERATION_RELEASE ]; then
      log "Could not find new genesis release (release: $genesis_release)"
      return 0
    fi

    reset_testnet $genesis_release
  fi
}

main() {
  if [[ "$force_reset" -eq 1 ]]; then
    log "Forced reset by user"
    reset_testnet "$(get_github_release "$genesis_repository")"
  else
    if ! [ -f $testnet_dir/genesis.json ]; then
      log "File genesis.json not found, resetting"
      reset_testnet "$(get_github_release "$genesis_repository")"
    else
      check_testnet
    fi
  fi
}

main
