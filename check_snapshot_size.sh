#!/bin/bash

echo -e "\nChecking snapshot file sizes...\n"

# URLs of snapshot files
SNAPSHOT_URL="https://kopi-services.luckystar.asia/kopi/luwak-1_latest.tar.gz"
WASM_URL="https://kopi-services.luckystar.asia/kopi/wasm_luwak-1_latest.tar.gz"

# Function to get size in GB
get_size_gb() {
  local url=$1
  size_bytes=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
  if [ -n "$size_bytes" ]; then
    awk -v size="$size_bytes" 'BEGIN { printf "%.2f GB\n", size / 1024 / 1024 / 1024 }'
  else
    echo "Unavailable"
  fi
}

# Print formatted table
printf "%-45s | %-10s\n" "File" "Size"
printf -- "-----------------------------------------------|-----------\n"
printf "%-45s | %-10s\n" "luwak-1_latest.tar.gz" "$(get_size_gb $SNAPSHOT_URL)"
printf "%-45s | %-10s\n" "wasm_luwak-1_latest.tar.gz" "$(get_size_gb $WASM_URL)"

