Kopi Daemon (kopid) Documentation
Overview
kopid is the command-line interface (CLI) and daemon for the Kopi blockchain, a Cosmos SDK-based, application-specific blockchain with the chain ID luwak-1. It enables users to run full nodes, validators, or interact with the Kopi network for tasks such as querying balances, sending transactions, and participating in governance. Built using the Cosmos SDK, kopid leverages modular architecture, Proof-of-Stake (PoS) consensus via CometBFT, and supports interoperability through the Inter-Blockchain Communication (IBC) protocol.
This documentation provides a comprehensive guide to installing, configuring, and using kopid to operate a node or interact with the Kopi network.

Table of Contents

Prerequisites
Installation
Quick Setup
Node Setup
Configuration
Running a Node
CLI Commands
Testing Your Node
Troubleshooting
Contributing
Resources


Prerequisites
Before installing and running kopid, ensure your system meets the following requirements:

Operating System: Ubuntu 20.04+ (or compatible Linux distribution)
Hardware:
CPU: 4 cores
RAM: 8 GB
Storage: 500 GB SSD (for mainnet, adjust for testnet)


Software:
Go 1.23.7+
GCC and Make
Git
Curl
Snapd (for Cosmovisor)


Network:
Open ports: 26656 (P2P), 26657 (RPC)
Stable internet connection


Dependencies:
lz4 for snapshot decompression
jq (optional, for JSON parsing)



Install dependencies on Ubuntu:
sudo apt-get update
sudo apt-get install -y make gcc lz4 snapd curl git


Installation
1. Install Go
Download and install Go 1.23.7:
wget https://go.dev/dl/go1.23.7.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.7.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin:/root/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

Expected output: go version go1.23.7 linux/amd64
2. Clone and Build Kopi
Clone the Kopi repository and compile kopid:
rm -rf ~/kopi
git clone --depth 1 --branch v19 https://github.com/kopi-money/kopi.git ~/kopi
cd ~/kopi
make install
make build

The kopid binary is installed in /root/go/bin.
3. Install Cosmovisor
Cosmovisor manages kopid upgrades:
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
cosmovisor version


Quick Setup
For a faster setup, you can use the official Kopi installation script, which automates the installation of dependencies, kopid, Cosmovisor, and node configuration. This is ideal for users who want to quickly deploy a node.
Run the Quick Setup Script
Execute the following command:
curl -s https://data.kopi.money/install.sh | sudo sh

What the Script Does

Installs Go 1.23.7 and required dependencies (gcc, make, lz4, snapd).
Clones the Kopi repository (v19 branch) and builds kopid.
Installs and configures Cosmovisor.
Sets up a systemd service for Cosmovisor.
Downloads the luwak-1 genesis file and blockchain snapshot.
Configures node settings (e.g., gas prices, seeds, peers, timeouts).
Starts the node automatically.

Important Notes

Security Warning: Always review the script’s contents before running it with sudo. Download and inspect it:
curl -s https://data.kopi.money/install.sh > install.sh
cat install.sh


Customization: The script uses default settings (e.g., chain ID luwak-1, port 26656). For custom configurations, use the manual Node Setup steps.

Post-Setup: After running, verify the node with the Testing Your Node steps.


If you prefer manual control or need to customize settings, follow the Installation and Node Setup sections instead.

Node Setup
1. Initialize the Node
Initialize your node with the chain ID luwak-1:
kopid init <moniker> --chain-id luwak-1

Replace <moniker> with your node’s name (e.g., my_node). This creates the ~/.kopid directory with default configuration files.
2. Download Genesis File
Fetch the genesis file for luwak-1:
wget https://data.kopi.money/genesis.json -O ~/.kopid/config/genesis.json

3. Download Snapshot
To sync quickly, download a blockchain snapshot:
curl -L https://kopi-services.luckystar.asia/kopi/luwak-1_latest.tar.gz | tar -xzf - -C ~/.kopid/data
curl -L https://kopi-services.luckystar.asia/kopi/wasm_luwak-1_latest.tar.gz | tar -xzf - -C ~/.kopid/wasm

4. Configure Cosmovisor
Set up Cosmovisor to manage kopid:
DAEMON_HOME="/root/.kopid" DAEMON_NAME="kopid" cosmovisor init /root/go/bin/kopid

Create a systemd service for Cosmovisor:
cat <<EOF > /etc/systemd/system/cosmovisor.service
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


Configuration
1. Node Configuration
Edit ~/.kopid/config/config.toml to configure P2P and RPC settings:

External Address: Set your node’s public IP (e.g., 52.221.96.139):
[p2p]
external_address = "52.221.96.139:26656"


Seeds and Peers: Use known nodes for connectivity:
seeds = "85919e3dcc7eec3b64bfdd87657c4fac307c9d23@65.109.34.145:26657"
persistent_peers = "85919e3dcc7eec3b64bfdd87657c4fac307c9d23@65.109.34.145:26657,38e9cbf8ebbdd62bd502f90d87550d7325190601@5.39.74.170:26716"


Consensus Timeouts: Optimize for performance:
[consensus]
timeout_propose = "300ms"
timeout_propose_delta = "50ms"
timeout_prevote = "100ms"
timeout_prevote_delta = "50ms"
timeout_precommit = "100ms"
timeout_precommit_delta = "50ms"
timeout_commit = "500ms"



2. Application Configuration
Edit ~/.kopid/config/app.toml to set gas prices:
minimum-gas-prices = "0ukopi"

3. Firewall Settings
Allow necessary ports:
sudo ufw allow 26656
sudo ufw allow 26657


Running a Node
1. Start the Node
Start the node using Cosmovisor:
sudo systemctl start cosmovisor.service

2. Monitor Logs
View real-time logs:
journalctl -f -u cosmovisor.service --output cat

Look for block processing messages (e.g., committed state, height=XXXX).
3. Stop the Node
Stop the service:
sudo systemctl stop cosmovisor.service


CLI Commands
kopid provides a rich CLI for interacting with the Kopi network. Below are common commands, grouped by category. Run kopid --help for a full list.
Node Management

Check Node Status:
kopid status --node http://<your-ip>:26657

Example: kopid status --node http://52.221.96.139:26657

Initialize Node:
kopid init <moniker> --chain-id luwak-1



Wallet Management

Create a Wallet:
kopid keys add <wallet-name> --keyring-backend file


List Wallets:
kopid keys list



Querying

Check Balance:
kopid query bank balances <address> --node http://<your-ip>:26657


Query Block:
kopid query block <height> --node http://<your-ip>:26657



Transactions

Send Tokens:
kopid tx bank send <from-address> <to-address> 100ukopi --chain-id luwak-1 --node http://<your-ip>:26657


Stake Tokens (Delegate):
kopid tx staking delegate <validator-address> 1000ukopi --from <wallet> --chain-id luwak-1



Governance

List Proposals:
kopid query gov proposals


Vote on a Proposal:
kopid tx gov vote <proposal-id> <yes/no> --from <wallet> --chain-id luwak-1



Cosmovisor

Check Version:
cosmovisor version


Prepare Upgrade:
cosmovisor prepare-upgrade




Testing Your Node
After starting your node, verify it’s running correctly:
1. Check Service Status
systemctl status cosmovisor.service

Ensure it’s active (running).
2. Monitor Logs
journalctl -f -u cosmovisor.service --output cat

Confirm blocks are being processed.
3. Check Sync Status
curl http://<your-ip>:26657/status

Check "sync_info"."catching_up". If false, the node is synced.
4. Verify Peers
curl http://<your-ip>:26657/net_info

Ensure "n_peers" is greater than 0.
5. Test Queries
Query a block:
curl http://<your-ip>:26657/block?height=100

Or use kopid:
kopid query block 100 --node http://<your-ip>:26657

6. Test External Connectivity
From another machine, check port 26656:
nc -zv <your-ip> 26656

7. Test Transactions
Create a wallet and send a test transaction (requires ukopi tokens):
kopid keys add test_wallet
kopid tx bank send <test_wallet_address> <recipient_address> 100ukopi --chain-id luwak-1 --node http://<your-ip>:26657


Troubleshooting

Node Not Syncing:
Verify seeds and persistent_peers in ~/.kopid/config/config.toml.
Ensure snapshot files were extracted correctly.
Check firewall and cloud provider security groups for port 26656.


Cosmovisor Fails to Start:
Check logs: journalctl -u cosmovisor.service -f.
Verify DAEMON_HOME and DAEMON_NAME in /etc/systemd/system/cosmovisor.service.


RPC Queries Fail:
Ensure port 26657 is open: sudo ufw allow 26657.
Check node status: kopid status.


High Resource Usage:
Normal during initial sync. Monitor with htop.
If persistent, optimize timeout_commit in config.toml.


Transaction Errors:
Ensure minimum-gas-prices = "0ukopi" in app.toml.
Verify wallet has sufficient ukopi tokens.



For specific errors, check the Kopi community (e.g., Discord, Telegram) or file an issue on GitHub.

Contributing
Contributions to kopid and the Kopi network are welcome! To contribute:

Fork the repository: github.com/kopi-money/kopi.
Create a branch: git checkout -b feature/<your-feature>.
Make changes and commit: git commit -m "Add feature".
Push to your fork: git push origin feature/<your-feature>.
Open a pull request.

See CONTRIBUTING.md for guidelines.

Resources

Official Kopi Repository: github.com/kopi-money/kopi
Cosmos SDK Documentation: docs.cosmos.network
Cosmovisor Guide: docs.cosmos.network/main/build/tooling/cosmovisor
Explorer: explorer.kopi.money (if available)
Community: Join Kopi’s Discord or Telegram for support.


License
This documentation is licensed under the MIT License. The Kopi software is licensed under the terms specified in the Kopi repository.

