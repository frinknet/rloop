#!/bin/bash

# © 2025 FRINKnet & Friends - MIT LICENSE

# If stdin has data (like from cat)
if [ ! -t 0 ]; then
  # treat first line as host, rest as ports
  read -r remote_host

  ports=()

  while read -r line && [ -n "$line" ]; do
    ports+=("$line")
  done
else
  if [ $# -lt 2 ]; then
    echo "Usage: $0 user@server port[:remote] ..."

    exit 1
  fi
  remote_host="$1"

  shift

  ports=("$@")
fi

tunnel_args=""

for mapping in "${ports[@]}"; do
  local_port="${mapping%%:*}"
  remote_port="${mapping##*:}"
  tunnel_args+=" -R ${remote_port}:localhost:${local_port}"
done

while true; do
  autossh -M 0 -N \
    -o "ServerAliveInterval=2" -o "ServerAliveCountMax=3" \
    -o "ExitOnForwardFailure=yes" "$remote_host" $tunnel_args

  sleep 2
done
