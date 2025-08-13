#!/bin/bash
# © 2025 FRINKnet & Friends - MIT LICENSE
# build.sh — produce self-contained installer with CLI-driven config
# USE THE SOURCE LUKE!!! (avoid the Dark Side of sed errors)

RLOOP_SRC="./rloop.sh"
[ ! -f "$RLOOP_SRC" ] && { echo "Missing $RLOOP_SRC — did you blow up the Death Star?"; exit 1; }

# Slurp rloop.sh into a var (midichlorians sold separately)
RLOOP_CODE="$(<"$RLOOP_SRC")"

# Build installer skeleton — Force-compatible
cat > install.sh <<EOF
#!/bin/bash
set -e

echo "= rloop installer — May the Ports Be With You ="

# --- 1. Grab args without Jedi mind tricks ---
SERVER="\$1"
shift || true
PORTS=("\$@")

# Require captain and crew (server + ports)
if [ -z "\$SERVER" ] || [ \${#PORTS[@]} -eq 0 ]; then
  echo "Usage: curl -sSL URL | sudo bash -s user@server port[:remote] ..."
  echo "Example: curl -sSL URL | sudo bash -s root@my.vps 8080:80 993 25"
  exit 1
fi

echo "[+] Checking for autossh will install if needed."

# --- 2. Install autossh (loyal droid) ---
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
    echo "No supported package manager found — install autossh manually and pray."
    exit 1
  fi
fi

# Save rebel battle plan to /etc/rlooprc
{
  echo "\$SERVER"
  for p in "\${PORTS[@]}"; do
    echo "\$p"
  done
} > /etc/rlooprc

echo "[+] Config saved to /etc/rlooprc — hide it from the Empire."

# --- 3. Drop rloop into /usr/local/bin ---
cat > /usr/local/bin/rloop <<'SCRIPT'
$RLOOP_CODE
SCRIPT

# --- 4. Give it authority ---
chmod +x /usr/local/bin/rloop

# --- 5. systemd holocron ---
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

# --- 5. Engage hyperdrive ---
systemctl daemon-reload
systemctl enable --now rloop

echo "= rloop is live... TRUST BUT VERIFY!!! ="
EOF

chmod +x install.sh
echo "[*] build.sh done — ready for rebel deployment via curl|bash."
