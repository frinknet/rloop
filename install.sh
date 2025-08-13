#!/bin/bash
set -e
echo "=== rloop installer (self-contained) ==="

# --- 1. Gather config FIRST ---
echo "Enter remote server (e.g. user@server):"
read -r SERVER
PORTS=()
while true; do
  read -p "Enter port (or local:remote mapping), blank to finish: " P
  [ -z "$P" ] && break
  PORTS+=("$P")
done

# Write /etc/rlooprc early
{
  echo "$SERVER"
  for p in "${PORTS[@]}"; do
    echo "$p"
  done
} > /etc/rlooprc
echo "[+] Config saved to /etc/rlooprc"

# --- 2. Install autossh ---
if ! command -v autossh >/dev/null; then
  echo "[*] Installing autossh..."
  if command -v apk >/dev/null; then
    apk update && apk add autossh
  elif command -v dnf >/dev/null; then
    dnf install -y autossh
  elif command -v apt-get >/dev/null; then
    apt-get update && apt-get install -y autossh
  elif command -v yum >/dev/null; then
    yum install -y autossh
  elif command -v pacman >/dev/null; then
    pacman -Sy --noconfirm autossh
  else
    echo "No supported package manager found — install autossh manually." ; exit 1
  fi
fi

# --- 3. Install rloop script ---
cat > /usr/local/bin/rloop <<'SCRIPT'
#!/bin/bash
# © 2025 FRINKnet & Friends - MIT LICENSE

TEST_MODE=0

# Sometimes we like to rehearse before the big gig
for arg in "$@"; do
  if [[ "$arg" == "--test" ]]; then
    TEST_MODE=1

    # Surgery without the anesthesia
    set -- "${@/--test/}"

    break
  fi
done

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
    echo "Usage: $0 [--test] user@server port[:remote] ..."
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


# TEST MODE RUNS ONCE, LIKE A NERVOUS AUDITION
if (( TEST_MODE )); then
  echo
  echo "Hold onto your butts!!!"
  echo
  echo "  Host: $remote_host"
  echo "  Ports: ${ports[*]}"
  echo

  autossh -M 0 -N \
    -o "ServerAliveInterval=2" -o "ServerAliveCountMax=3" \
    -o "ExitOnForwardFailure=yes" "$remote_host" $tunnel_args

  local err=$?

  echo

  if (( err == 0 )); then
    echo "  This was just a drill. Nobody died. Yet."
  else
    echo "  Aparently we did not survive that one."
  fi

  echo
  echo "autossh -M 0 -N -o 'ServerAliveInterval=2' -o 'ServerAliveCountMax=3' -o 'ExitOnForwardFailure=yes' $remote_host $tunnel_args"
  echo

  exit $err
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
SCRIPT
chmod +x /usr/local/bin/rloop

# --- 4. Install systemd service ---
cat > /etc/systemd/system/rloop.service <<SERVICE
[Unit]
Description=Persistent autossh multi-port reverse tunnel via rloop
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'cat /etc/rlooprc | /usr/local/bin/rloop'
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE

# --- 5. Enable and start ---
systemctl daemon-reload
systemctl enable --now rloop
echo "=== Installation complete. rloop is live. ==="
