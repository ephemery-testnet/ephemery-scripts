#!/bin/bash

# The following variables may be defined as standard environment variables or
# may be defined in a file that is passed as the first argument to this
# script. You may also simple set your desired values as the "default_" values
# in the code below.
#
# TESTNET_DIR - Required: Directory containing testnet configuration files
# EL_CLIENT - Required: Lowercase name of execution client (i.e. besu, erigon,
#           geth, nethermind, reth)
# EL_SERVICE - Required: The name of the systemd service to start/stop the
#           execution client
# EL_DATADIR - Required: The data directory of the execution client
# EL_USER - Optional: The user as which the execution client runs. Required for
#           genesis initialization for some execution client. If left blank,
#           the genesis initialization will run as the same user the script
#           is running as.
# CL_CLIENT - Required: Lowercase name of consensus client (i.e. prysm, teku,
#           lodestar, nimbus, lighthouse)
# CL_SERVICE - Required: The name of the systemd service to start/stop the
#           consensus client
# CL_DATADIR - Required: The data directory of the consensus client
# CL_PORT - Optional: HTTP REST port for consensus client. Defaults to 3500
# VC_CLIENT - Optional: Lowercase name of the validator client (i.e. prysm,
#           teku, lodestar, nimbus, lighthouse). Leave blank if using single-
#           process consensus/validator client.
# VC_SERVICE - Optional: The name of the systemd service to start/stop the
#           validator client. Leave blank if using a single-process 
#           consensus/validator client.
# VC_DATADIR - Optional: The data directory of the validator client. Leave
#           blank if using a single-process consensus/validator client.
# TESTNET_FILES_USER - Optional: The user that should own the testnet files.
#           If left blank, the testnet files will be owned by the same user
#           the script is running as.
# TESTNET_FILES_GROUP - Optional: The group that the testnet files should
#           belong to. If left blank, the testnet files will belong to the
#           same group the script is running as.

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
default_el_user=

# consensus
default_cl_client=
default_cl_service=
default_cl_datadir=
default_cl_port=3500

# validator
default_vc_client=
default_vc_service=
default_vc_datadir=

# Testnet Files Ownership
default_testnet_files_user=
default_testnet_files_group=

## Read environment variables, if present

testnet_dir=${TESTNET_DIR:-$default_testnet_dir}

el_client=${EL_CLIENT:-$default_el_client}
el_service=${EL_SERVICE:-$default_el_service}
el_datadir=${EL_DATADIR:-$default_el_datadir}
el_user=${EL_USER:-$default_el_user}

cl_client=${CL_CLIENT:-$default_cl_client}
cl_service=${CL_SERVICE:-$default_cl_service}
cl_datadir=${CL_DATADIR:-$default_cl_datadir}
cl_port=${CL_PORT:-$default_cl_port}

vc_client=${VC_CLIENT:-$default_vc_client}
vc_service=${VC_SERVICE:-$default_vc_service}
vc_datadir=${VC_DATADIR:-$default_vc_datadir}

testnet_files_user=${TESTNET_FILES_USER:-$default_testnet_files_user}
testnet_files_group=${TESTNET_FILES_GROUP:-$default_testnet_files_group}

# Set FORCE_RESET environment variable to 1 test reset
force_reset="${FORCE_RESET:-0}"

start_client() {
  local client_service="$1"
  
  if [ -n "$client_service" ]; then
    log "Starting $client_service systemd service"
    cmd=("/bin/systemctl" "start" "$client_service")
    "${cmd[@]}"
  fi
}

stop_client() {
  local client_service="$1"

  if [ -n "$client_service" ]; then
    log "Stopping $client_service systemd service"
    cmd=("/bin/systemctl" "stop" "$client_service")
    "${cmd[@]}"
  fi
}

clear_execution_datadir() {
  # Ensure $el_datadir is a valid directory before proceeding
  if [ -z "$el_datadir" ] || [ ! -d "$el_datadir" ]; then
    log "Execution data directory $el_datadir is invalid or does not exist."
    return 1
  fi

  case "$el_client" in
    "geth")
      # Delete everything in $el_datadir/geth/* except for nodekey
      if [ -d "$el_datadir/geth" ]; then
        find_cmd=("find" "$el_datadir/geth" "-mindepth" "1" "-maxdepth" "1" "!" "-name" "nodekey" "-exec" "rm" "-rf" "{}" "+")
        "${find_cmd[@]}"
        log "Retained nodekey file in $el_datadir and deleted other contents for $el_client execution client"
      fi
      ;;

    "erigon")
      # Delete everything in $el_datadir except for config.json and customGenesis.json
      if [ -d "$el_datadir" ]; then
        find_cmd=("find" "$el_datadir" "!" "-name" "config.json" "!" "-name" "customGenesis.json" "-type" "f" "-delete")
        "${find_cmd[@]}"
        log "Retained config.json and customGenesis.json files in $el_datadir and deleted other contents for $el_client execution client"
      fi
      ;;

    *)
      # Delete everything in $el_datadir for other clients
      if [ -d "$el_datadir" ]; then
        rm_cmd=("rm" "-rf" "$el_datadir"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $el_datadir/ for $el_client execution client"
      fi
      ;;
  esac
}


clear_consensus_datadir() {
  # Ensure $cl_datadir is a valid directory before proceeding
  if [ -z "$cl_datadir" ] || [ ! -d "$cl_datadir" ]; then
    log "Consensus data directory '$cl_datadir' is invalid or does not exist."
    return 1
  fi

  case "$cl_client" in
    "teku")
      # Delete everything in $cl_datadir/beacon/* except for kvstore
      if [ -d "$cl_datadir/beacon" ]; then
        find_cmd=("find" "$cl_datadir/beacon" "-mindepth" "1" "-maxdepth" "1" "!" "-name" "kvstore" "-exec" "rm" "-rf" "{}" "+")
        "${find_cmd[@]}"
        log "Retained kvstore file in $cl_datadir/beacon and deleted other contents for $cl_client consensus client"
      fi

      # Clear logs directory
      if [ -d "$cl_datadir/logs" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/logs"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $cl_datadir/logs for $cl_client consensus client"
      fi

      # Delete slashprotection.sqlite if present
      if [ -f "$cl_datadir/slashprotection/slashprotection.sqlite" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/slashprotection/slashprotection.sqlite")
        "${rm_cmd[@]}"
        log "Deleted $cl_datadir/slashprotection/slashprotection.sqlite for $cl_client consensus client"
      fi
      ;;

    "lighthouse")
      # Delete everything in $cl_datadir/beacon/* except for network
      if [ -d "$cl_datadir/beacon" ]; then
        find_cmd=("find" "$cl_datadir/beacon" "-mindepth" "1" "-maxdepth" "1" "!" "-name" "network" "-exec" "rm" "-rf" "{}" "+")
        "${find_cmd[@]}"
        log "Retained network file in $cl_datadir/beacon and deleted other contents for $cl_client consensus client"
      fi

      # Clear slashing_protection.sqlite
      if [ -f "$cl_datadir/keys/slashing_protection.sqlite" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/keys/slashing_protection.sqlite")
        "${rm_cmd[@]}"
        log "Deleted $cl_datadir/keys/slashing_protection.sqlite for $cl_client consensus client"
      fi
      ;;

    "lodestar")
      # Delete chain-db if present
      if [ -d "$cl_datadir/chain-db" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/chain-db"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $cl_datadir/chain-db for $cl_client consensus client"
      fi

      # Delete validator-db if present
      if [ -d "$cl_datadir/validator-db" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/validator-db"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $cl_datadir/validator-db for $cl_client consensus client"
      fi
      ;;

    "nimbus")
      # Clear all contents in $cl_datadir
      if [ -d "$cl_datadir" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $cl_datadir data directory for $cl_client consensus client"
      fi

      # Clear slashing_protection.sqlite3
      if [ -f "$vc_datadir/validators/slashing_protection.sqlite3" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/validators/slashing_protection.sqlite3")
        "${rm_cmd[@]}"
        log "Deleted $cl_datadir/validators/slashing_protection.sqlite3 for $cl_client consensus client"
      fi
      ;;

    "prysm")
      # Clear all contents in $cl_datadir
      if [ -d "$cl_datadir" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $cl_datadir data directory for $cl_client consensus client"
      fi

      # Clear validator.db
      if [ -f "$vc_datadir/prysm-wallet-v2/direct/validator.db" ]; then
        rm_cmd=("rm" "-rf" "$cl_datadir/prysm-wallet-v2/direct/validator.db")
        "${rm_cmd[@]}"
        log "Deleted $cl_datadir/prysm-wallet-v2/direct/validator.db for $cl_client consensus client"
      fi
      ;;
  esac
}


clear_validator_datadir() {
 
  if [ -z "$vc_client" ]; then
    log "Validator client undefined."
    return
  fi
  
  if [ -z "$vc_datadir" ] || [ ! -d "$vc_datadir" ]; then
    log "Validator data directory '$vc_datadir' is invalid or does not exist."
    return
  fi

  # Only proceed if both $vc_client and $vc_service are set
  case "$vc_client" in
    "prysm")
      if [ -f "$vc_datadir/prysm-wallet-v2/direct/validator.db" ]; then
        rm_cmd=("rm" "-rf" "$vc_datadir/prysm-wallet-v2/direct/validator.db")
        "${rm_cmd[@]}"
        log "Deleted $vc_datadir/prysm-wallet-v2/direct/validator.db for $vc_client validator client"
      fi
      ;;

    "teku")
      if [ -f "$vc_datadir/slashprotection/slashprotection.sqlite" ]; then
        rm_cmd=("rm" "-rf" "$vc_datadir/slashprotection/slashprotection.sqlite")
        "${rm_cmd[@]}"
        log "Deleted $vc_datadir/slashprotection/slashprotection.sqlite for $vc_client validator client"
      fi
      ;;

    "nimbus")
      if [ -f "$vc_datadir/validators/slashing_protection.sqlite3" ]; then
        rm_cmd=("rm" "-rf" "$vc_datadir/validators/slashing_protection.sqlite3")
        "${rm_cmd[@]}"
        log "Deleted $vc_datadir/validators/slashing_protection.sqlite3 for $vc_client validator client"
      fi
      ;;

    "lighthouse")
      if [ -f "$vc_datadir/keys/slashing_protection.sqlite" ]; then
        rm_cmd=("rm" "-rf" "$vc_datadir/keys/slashing_protection.sqlite")
        "${rm_cmd[@]}"
        log "Deleted $vc_datadir/keys/slashing_protection.sqlite for $vc_client validator client"
      fi
      ;;

    "lodestar")
      # Delete validator-db if present
      if [ -d "$vc_datadir/validator-db" ]; then
        rm_cmd=("rm" "-rf" "$vc_datadir/validator-db"/*)
        "${rm_cmd[@]}"
        log "Deleted contents of $vc_datadir/validator-db/ for $vc_client validator client"
      fi
      ;;
  esac
}


setup_genesis() {
  # Check for $el_user to determine if we will sudo the genesis command
  if [[ "$el_user" =~ ^[a-zA-Z0-9_-]+$ ]] && id -u "$el_user" >/dev/null 2>&1; then
    cmd=("sudo" "-u" "$el_user")
  else
    cmd=()
  fi

  case "$el_client" in
    "geth")
      if [ -z "$el_datadir" ] || [ -z "$testnet_dir" ]; then
        log "Cannot initialize geth. Missing el_datadir or testnet_dir variable values."
      else
        log "Initializing geth genesis"
        cmd+=("geth" "init" "--datadir" "$el_datadir" "$testnet_dir/genesis.json")
        "${cmd[@]}"
      fi
      ;;

    "erigon")
      if [ -z "$el_datadir" ] || [ -z "$testnet_dir" ]; then
        log "Cannot initialize geth. Missing el_datadir or testnet_dir variable values."
      else
        log "Initializing erigon genesis"
        cmd+=("erigon" "init" "--datadir" "$el_datadir" "$testnet_dir/genesis.json")
        "${cmd[@]}"
      fi
      ;;
  esac
}


get_github_release() {
  # Validate the repository format to allow only valid GitHub repository characters
  local repo="$1"
  if [[ ! "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9._-]+$ ]]; then
    log "Invalid repository format: $repo"
    return 1
  fi

  # Fetch the latest release tag
  curl --silent "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    head -n 1
}


download_genesis_release() {
  local genesis_release="$1"

  # Validate genesis release format (allowing alphanumeric, dots, hyphens, underscores)
  if [[ ! "$genesis_release" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    log "Invalid genesis release format: $genesis_release"
    return 1
  fi

  # Remove old genesis files
  if [ -d "$testnet_dir" ]; then
    rm_cmd=("rm" "-rf" "$testnet_dir"/*)
    "${rm_cmd[@]}"
    log "Removed existing files from testnet directory $testnet_dir"
  else
    # Use mkdir in a command array
    mkdir_cmd=("mkdir" "-p" "$testnet_dir")
    "${mkdir_cmd[@]}"
    log "Created testnet directory $testnet_dir"
  fi

  # Fetch and extract the latest genesis files
  log "Getting latest genesis files and unpacking into $testnet_dir"
  wget_cmd=("wget" "-qO-" "https://github.com/$genesis_repository/releases/download/$genesis_release/testnet-all.tar.gz")
  tar_cmd=("tar" "xvz" "-C" "$testnet_dir")
  "${wget_cmd[@]}" | "${tar_cmd[@]}" > /dev/null 2>&1

  # Reset ownership if testnet_files_user and testnet_files_group are set and exist
  if [[ -n "$testnet_files_user" && -n "$testnet_files_group" ]]; then
      if [[ "$testnet_files_user" =~ ^[a-zA-Z0-9_-]+$ ]] && id -u "$testnet_files_user" >/dev/null 2>&1 &&
         [[ "$testnet_files_group" =~ ^[a-zA-Z0-9_-]+$ ]] && getent group "$testnet_files_group" >/dev/null 2>&1; then
         
          chown_cmd=("chown" "-R" "$testnet_files_user:$testnet_files_group" "$testnet_dir")
          "${chown_cmd[@]}"
          log "Reset ownership and group of testnet genesis files in $testnet_dir to $testnet_files_user:$testnet_files_group"
      else
          log "Invalid user or group: $testnet_files_user or $testnet_files_group does not exist"
      fi
  fi

}


reset_testnet() { 

  stop_client $el_service
  stop_client $cl_service

  if [ -n "$vc_service" ]; then
    stop_client $vc_service
  fi

  clear_execution_datadir
  clear_consensus_datadir

  download_genesis_release $1
  setup_genesis

  if [ -n "$vc_service" ]; then
    clear_validator_datadir
    start_client $vc_service
  fi

  start_client $el_service
  start_client $cl_service
}


check_testnet() {
  current_time=$(date +%s)

  # Use a command array for curl to retrieve genesis time
  curl_cmd=("curl" "-s" "--fail" "http://127.0.0.1:$cl_port/eth/v1/beacon/genesis")
  genesis_time=$("${curl_cmd[@]}" | sed 's/.*"genesis_time":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')

  if [ $? -ne 0 ] || [ -z "$genesis_time" ]; then
    log "Failed to retrieve genesis time from beacon node or empty response."
    return 1
  fi

  if ! [[ "$genesis_time" =~ ^[0-9]+$ ]]; then
    log "Invalid genesis time format: '$genesis_time'"
    return 1
  fi

  if [ "$genesis_time" -le 0 ]; then
    log "Genesis time is not greater than 0, received: $genesis_time"
    return 1
  fi

  # Verify retention file exists and source it if so
  if [ ! -f "$testnet_dir/retention.vars" ]; then
    log "Could not find retention.vars"
    return 0
  fi
  source "$testnet_dir/retention.vars"

  # Calculate the timeout for the testnet
  testnet_timeout=$((genesis_time + GENESIS_RESET_INTERVAL - timeout_window))
  log "Genesis timeout: $((testnet_timeout - current_time)) sec ($(date -d "@$testnet_timeout" '+%Y-%m-%d %H:%M:%S'))"

  if [ "$testnet_timeout" -le "$current_time" ]; then
    genesis_release=$(get_github_release "$genesis_repository")
    if [ -z "$ITERATION_RELEASE" ]; then
      ITERATION_RELEASE="$CHAIN_ID"
    fi

    if [ "$genesis_release" = "$ITERATION_RELEASE" ]; then
      log "Could not find new genesis release (release: $genesis_release)"
      return 0
    fi

    reset_testnet "$genesis_release"
  fi
}


main() {

  # Collect missing variables into an array
  missing_vars=()
  for var_name in "testnet_dir" "el_client" "el_service" "el_datadir" \
                  "cl_client" "cl_service" "cl_datadir"; do
    if [[ -z "${!var_name}" ]]; then
      missing_vars+=("$var_name")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log "Error: The following required variables are missing or empty: ${missing_vars[*]}"
    exit 1
  fi

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
