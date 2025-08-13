#!/bin/bash
# © 2025 FRINKnet & Friends - MIT LICENSE

# If stdin has data (like from cat)
if [ ! -t 0 ]; then
  # treat first line as host, rest as ports
  read -r remote_host

  ports=()

  # get em all
  while read -r line && [ -n "$line" ]; do
    ports+=("$line")
  done
else
  # if the user is stupid die nicely
  if [ $# -lt 2 ]; then
    echo "Usage: $0 user@server port[:remote] ..."
    
    exit 1
  fi

  # otherwise hopefully we're good to go
  remote_host="$1"
  shift
  ports=("$@")
fi

# If host is number or port die a bloody
if [[ "$remote_host" =~ ^[0-9]+$ ]] || [[ "$remote_host" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Error: '$remote_host' looks suspiciously like a port or a bad IP." >&2

  exit 2
fi

tunnel_args=""

# Get 'em PORTS!!!
for mapping in "${ports[@]}"; do
  local_port="${mapping%%:*}"
  remote_port="${mapping##*:}"

  # If either port is empty or NaN commit suicide
  if [[ -z "$local_port" || -z "$remote_port" ]]; then
    echo "Error: mapping '$mapping' is malformed... Terminating with EXTREME PREJUDICE!!!" >&2
    
    exit 3
  fi
  
  # If either port is wrong tell the user you're angry
  if ! [[ "$local_port" =~ ^[0-9]+$ && "$remote_port" =~ ^[0-9]+$ ]]; then
    echo "Error: mapping '$mapping' contains non-numeric ports... RAGE QUITTING NOW!!!" >&2
    
    exit 4
  fi

  # Otherwise we might make it...
  tunnel_args+=" -R ${remote_port}:localhost:${local_port}"
done

# But if no ports die screaming...
if [[ -z "$tunnel_args" ]]; then
  echo "Error: no valid ports specified... SCREAMING IN THE VOID!!!" >&2
  exit 5
fi

# Otherwise we can do this
while true; do
  # It should stay connected
  autossh -M 0 -N \
    -o "ServerAliveInterval=2" -o "ServerAliveCountMax=3" \
    -o "ExitOnForwardFailure=yes" "$remote_host" $tunnel_args

  # But if not give a moment to breath
  sleep 2

  # Don't stop. Try again... FOREVER!!!
done
