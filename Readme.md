# Kopi Daemon (`kopid`) Documentation

## Overview

`kopid` is the command-line interface (CLI) and daemon for the Kopi blockchain, a Cosmos SDK-based, application-specific blockchain with the chain ID `luwak-1`. It enables users to run full nodes, validators, or interact with the Kopi network for tasks such as querying balances, sending transactions, and participating in governance.

Built using the Cosmos SDK, `kopid` leverages modular architecture, Proof-of-Stake (PoS) consensus via CometBFT, and supports interoperability through the Inter-Blockchain Communication (IBC) protocol.

This documentation provides a comprehensive guide to installing, configuring, and using `kopid` to operate a node or interact with the Kopi network.

---

## Table of Contents

1. Prerequisites  
2. Installation  
3. Quick Setup  
4. Node Setup  
5. Configuration  
6. Running a Node  
7. CLI Commands  
8. Testing Your Node  
9. Troubleshooting  
10. Contributing  
11. Resources  

---

## Prerequisites

Before installing and running `kopid`, ensure your system meets the following requirements:

- **Operating System**: Ubuntu 20.04+ (or compatible Linux distribution)  
- **Hardware**:
  - CPU: 4 cores  
  - RAM: 8 GB  
  - Storage: 500 GB SSD (mainnet; adjust for testnet)
- **Software**:
  - Go 1.23.7+
  - GCC and Make
  - Git
  - Curl
  - Snapd (for Cosmovisor)
- **Network**:
  - Open ports: `26656` (P2P), `26657` (RPC)
  - Stable internet connection
- **Dependencies**:
  - `lz4` for snapshot decompression
  - `jq` (optional, for JSON parsing)

Install dependencies on Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y make gcc lz4 snapd curl git
```
# Kopi Node Installation Guide

## Installation

### 1. Install Go  
Download and install Go 1.23.7:

```bash
wget https://go.dev/dl/go1.23.7.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.7.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin:/root/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version
```

Expected output:
```
go version go1.23.7 linux/amd64
```

### 2. Clone and Build Kopi

```bash
rm -rf ~/kopi
git clone --depth 1 --branch v19 https://github.com/kopi-money/kopi.git ~/kopi
cd ~/kopi
make install
make build
```

The `kopid` binary will be installed in `/root/go/bin`.

### 3. Install Cosmovisor

```bash
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
cosmovisor version
```

## Quick Setup

Run the official installation script for a fast setup:

```bash
curl -s https://data.kopi.money/install.sh | sudo sh
```

### ⚙️ What the Script Does

- **Run from Home Directory**: Avoid `sh: 0: getcwd() failed` errors by running the script from `~/`

- Installs Go 1.23.7 and required dependencies  
- Clones the Kopi repository (v19 branch) and builds kopid  
- Installs and configures Cosmovisor  
- Sets up a systemd service  
- Downloads the luwak-1 genesis file and snapshot  
- Configures node settings  
- Starts the node  

**Security**: Review the script before executing:

```bash
curl -s https://data.kopi.money/install.sh > install.sh
cat install.sh
```

**Customization**: For manual control, follow the Installation and Node Setup sections.

## Node Setup

### 1. Initialize the Node

```bash
kopid init <node_name> --chain-id luwak-1
```

### 2. Download Genesis File

```bash
wget https://data.kopi.money/genesis.json -O ~/.kopid/config/genesis.json
```

### 3. Download Snapshot

```bash
curl -L https://kopi-services.luckystar.asia/kopi/luwak-1_latest.tar.gz | tar -xzf - -C ~/.kopid/data
curl -L https://kopi-services.luckystar.asia/kopi/wasm_luwak-1_latest.tar.gz | tar -xzf - -C ~/.kopid/wasm
```

### 4. Configure Cosmovisor

```bash
DAEMON_HOME="/root/.kopid"
DAEMON_NAME="kopid"
cosmovisor init /root/go/bin/kopid
```

Create the systemd service:

```bash
cat << EOF | sudo tee /etc/systemd/system/cosmovisor.service
[Unit]
Description=Cosmovisor daemon
After=network-online.target

[Service]
Environment="DAEMON_NAME=kopid"
Environment="DAEMON_HOME=/root/.kopid"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_POLL_INTERVAL=300ms"
Environment="DAEMON_DATA_BACKUP_DIR=/root/.kopid"
Environment="UNSAFE_SKIP_BACKUP=false"
Environment="DAEMON_PREUPGRADE_MAX_RETRIES=0"
User=root
ExecStart=/root/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cosmovisor.service
```

## Configuration

### 1. Node Configuration

Edit `~/.kopid/config/config.toml`:

```toml
[p2p]
external_address = "52.221.96.139:26656"
seeds = "85919e3dcc7eec3b64bfdd87657c4fac307c9d23@65.109.34.145:26657"
persistent_peers = "85919e3dcc7eec3b64bfdd87657c4fac307c9d23@65.109.34.145:26657,38e9cbf8ebbdd62bd502f90d87550d7325190601@5.39.74.170:26716"

[consensus]
timeout_propose = "300ms"
timeout_propose_delta = "50ms"
timeout_prevote = "100ms"
timeout_prevote_delta = "50ms"
timeout_precommit = "100ms"
timeout_precommit_delta = "50ms"
timeout_commit = "500ms"
```

### 2. Application Configuration

In `~/.kopid/config/app.toml`:

```toml
minimum-gas-prices = "0ukopi"
```

### 3. Firewall Settings

```bash
sudo ufw allow 26656
sudo ufw allow 26657
```

## Running a Node

### 1. Start the Node

```bash
sudo systemctl start cosmovisor.service
```

### 2. Monitor Logs

```bash
journalctl -f -u cosmovisor.service --output cat
```

### 3. Stop the Node

```bash
sudo systemctl stop cosmovisor.service
```

## CLI Commands

### Node Management

```bash
kopid status --node http://<your_ip>:26657
kopid init --chain-id luwak-1
```

### Wallet Management

```bash
kopid keys add <wallet_name> --keyring-backend file
kopid keys list
```

### Querying

```bash
kopid query bank balances <wallet_address>
```

## Transactions

### Send Tokens

```bash
kopid tx bank send <from_wallet> <to_address> <amount> --fees 5000ukopi --chain-id luwak-1 --keyring-backend file
```

### Delegate Stake

```bash
kopid tx staking delegate <validator_address> <amount> --from <wallet_name> --chain-id luwak-1 --gas auto --gas-adjustment 1.3 --keyring-backend file
```

### Withdraw Rewards

```bash
kopid tx distribution withdraw-rewards <validator_address> --from <wallet_name> --chain-id luwak-1 --keyring-backend file --commission
```

### Vote on Proposals

```bash
kopid tx gov vote <proposal_id> <yes|no|abstain|no_with_veto> --from <wallet_name> --chain-id luwak-1 --keyring-backend file
```

## Testing Your Node

### Check Sync Status

```bash
kopid status --node http://localhost:26657 | jq '.SyncInfo'
```

### Check Latest Block Height

```bash
curl -s localhost:26657/status | jq '.result.sync_info.latest_block_height'
```

## Troubleshooting

- **Out of Sync**: Ensure correct genesis file and snapshot are downloaded.  
- **Cosmovisor not starting**: Check service logs:

```bash
journalctl -xeu cosmovisor.service
```

- **Port Issues**: Verify ports 26656 and 26657 are open.  
- **Missing Go path**: Add to `.bash_profile`:

```bash
export PATH=$PATH:/usr/local/go/bin:/root/go/bin
source ~/.bash_profile
```

## Contributing

We welcome contributions! Please:

```bash
git checkout -b feature-name
git commit -am 'Add new feature'
git push origin feature-name
```

Then open a Pull Request.

## Resources

- Website: https://kopi.money  
- Docs: https://docs.kopi.money  
- Explorer: https://explorer.kopi.money  
- Telegram: https://t.me/+_hk--L9mKKc4MThk
- Discord: https://discord.gg/GvnwSwsCcs
- Twitter: https://twitter.com/kopi_money
- GitHub: https://github.com/kopi-money/kopi



