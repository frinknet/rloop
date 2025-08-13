#!/bin/bash
# © 2025 FRINKnet & Friends - MIT LICENSE
# build.sh — produce self-contained installer with CLI-driven config
# USE THE SOURCE LUKE!!!

RLOOP_SRC="./rloop.sh"
[ ! -f "$RLOOP_SRC" ] && { echo "Missing $RLOOP_SRC — did you nuke it?"; exit 1; }

RLOOP_CODE="$(<"$RLOOP_SRC")"

# THESE ARE THE DROIDS YOU NEED!!!
cat > install.sh <<'EOF'
#!/bin/bash
set -e

echo "= rloop installer (self-contained) ="

# --- 1. Grab args without whining ---
SERVER="$1"
shift || true
PORTS=("$@")

# We require a brain and at least one port mapping
if [ -z "$SERVER" ] || [ ${#PORTS[@]} -eq 0 ]; then
  echo "Usage: curl -sSL URL | sudo bash -s user@server port[:remote] ..."
  echo "Example: curl -sSL URL | sudo bash -s root@my.vps 8080:80 993 25"
  exit 1
fi

# Write /etc/rlooprc right now before anyone changes their mind
{
  echo "$SERVER"
  for p in "${PORTS[@]}"; do
    echo "$p"
  done
} > /etc/rlooprc

echo "[+] Config saved to /etc/rlooprc — print it, frame it, cherish it."

# --- 2. Install autossh (our irrationally loyal tunnel butler) ---
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
    echo "No supported package manager found — install autossh manually and pray." ; exit 1
  fi
fi

# --- 3. Drop the actual rloop script into /usr/local/bin like a crown jewel ---
cat > /usr/local/bin/rloop <<'SCRIPT'
RLOOP_PLACEHOLDER
SCRIPT
chmod +x /usr/local/bin/rloop

# --- 4. Summon systemd to do our eternal bidding ---
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

# --- 5. Bring forth the daemon ---
systemctl daemon-reload
systemctl enable --now rloop

echo "= Installation complete. rloop is live. Try not to cry when it Just Works. ="
EOF

# drop actual rloop.sh code into the placeholder
sed -i "s|RLOOP_PLACEHOLDER|$RLOOP_CODE|g" install.sh

chmod +x install.sh
echo "[*] build.sh done — feed to the masses via curl|bash without blocking on silly readline prompts."

