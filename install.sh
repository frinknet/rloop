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
