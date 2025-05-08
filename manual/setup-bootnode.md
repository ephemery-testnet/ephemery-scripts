# Ephemery Consensus Bootnode Setup Guide

This guide describes how to **create and operate a consensus layer bootnode** for the Ephemery network.

Bootnodes provide essential peer discovery services during the startup phase of the network. Operating one on Ephemery involves a few specific steps due to how genesis files are created and distributed.

---

## ❗ Key Requirements

- A **static public IP address**
- A **stable internet connection**
- A client that can **persist and expose its node identity (ENR)** in a reproducible format

✅ Supported clients:
- `teku`
- `lighthouse` (beacon node)
- `lh_bootnode` (Lighthouse in bootnode-only mode)

---

## 🔐 Bootnode Identity Flow

Bootnodes must run with a pre-defined node identity so that their ENRs can be embedded into the genesis files. The flow is as follows:

1. The **genesis generator** creates private keys for each bootnode.
2. These keys are **encrypted** using an RSA **public key** you provide.
3. The bootnode **decrypts and uses** this key to ensure its identity matches the ENR embedded in genesis.

---

## 🛠 Setup Steps

### Step 1: Generate RSA Key Pair

```sh
mkdir bootnode-keys
cd bootnode-keys

# Generate private key (keep this secret!)
openssl genrsa -out bootnode_pk.pem 2048

# Generate public key to share
openssl rsa -in bootnode_pk.pem -pubout > bootnode_pk.pub
```

---

### Step 2: Submit Bootnode Configuration

1. **Add your public key** (`bootnode_pk.pub`) to the Ephemery genesis repository:  
   [ephemery-genesis/bootnode-keys](https://github.com/ephemery-testnet/ephemery-genesis/tree/master/bootnode-keys)

2. **Update `cl-bootnodes.txt`** with your bootnode's entry:

Format:
```text
<type>:<name>:<ip>:<port>
```

- `type`: `teku`, `lighthouse`, or `lh_bootnode`
- `name`: RSA key name (omit `.pub`)
- `ip`: Static public IP
- `port`: TCP port to expose

Example:
```text
teku:bootnode_eph1:137.74.203.240:9100
lh_bootnode:bootnode_pk:65.109.154.46:9001
lighthouse:bootnode_pk2:167.235.1.185:9040
```

---

### Step 3: Decrypt and Load Bootnode Key at Runtime

The testnet release will contain:
- An encrypted key: `bootnode_name.key.enc`
- A matching ENR: `bootnode_name.enr` (for `lh_bootnode` only)
These files are included within the latest genesis release (`bootnode-keys` folder).

---

### 🔓 Decryption Example: Teku

```sh
# Define your environment
cl_datadir=~/data-boot
bootnode_name=bootnode_eph1
testnet_dir=~/testnet
key_path=~/bootnode-keys/$bootnode_name.pem

# Create kvstore directory and decrypt key
mkdir -p $cl_datadir/beacon/kvstore
openssl rsautl -decrypt \
  -inkey $key_path \
  -in $testnet_dir/bootnode-keys/$bootnode_name.key.enc \
  > $cl_datadir/beacon/kvstore/generated-node-key.dat
```

---

### 🔓 Decryption Example: Lighthouse (Beacon Node)

```sh
# Define your environment
client_datadir=~/data-boot
bootnode_name=bootnode_eph1
testnet_dir=~/testnet
key_path=~/bootnode-keys/$bootnode_name.pem

# Create network directory and decrypt key
mkdir -p $client_datadir/beacon/network
openssl rsautl -decrypt \
  -inkey $key_path \
  -in $testnet_dir/bootnode-keys/$bootnode_name.key.enc \
  > $client_datadir/beacon/network/key
```

> Note: Lighthouse beacon node **does not require** `enr.dat` file, as it regenerates it from the private key.

---

### 🔓 Decryption Example: Lighthouse Bootnode (`lh_bootnode`)

```sh
# Define your environment
client_datadir=~/data-boot
bootnode_name=bootnode_eph1
testnet_dir=~/testnet
key_path=~/bootnode-keys/$bootnode_name.pem

# Prepare network directory
mkdir -p $client_datadir/beacon/network

# Decrypt the bootnode private key
openssl rsautl -decrypt \
  -inkey $key_path \
  -in $testnet_dir/bootnode-keys/$bootnode_name.key.enc \
  > $client_datadir/beacon/network/key

# Flatten and store the ENR
cat $testnet_dir/bootnode-keys/$bootnode_name.enr | tr '\n' ' ' | sed -e 's/ //g' > $client_datadir/beacon/network/enr.dat
```

---

## 🔄 Updating Your Bootnode Info

To change your IP or port:
1. Generate a new RSA keypair.
2. Update your public key and `cl-bootnodes.txt` entry in the genesis repo.
3. Wait for the next testnet reset to pick up the change.

---

## 📝 Notes

- Do **not regenerate** keys manually; always use the encrypted keys provided in the genesis release.
- Use **static IPs** with guaranteed availability.
- Integrate the decryption logic into your reset script.

---

## ✅ Checklist

- [ ] Generated and stored RSA keypair
- [ ] Added public key to genesis repo
- [ ] Added bootnode entry to `cl-bootnodes.txt`
- [ ] Decryption and ENR logic integrated
- [ ] Bootnode runs with correct ENR and static IP

---