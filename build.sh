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

echo
echo "= rloop installer — May the Ports Be With You. ="
echo

# Use the source Luke
parse() {
  local prev=

  # Search your feelings
  for arg in "\$@"; do
    # These are the droids we are looking for
    if [[ "\$arg" =~ [^0-9:] ]]; then
      [[ -n "\$prev" ]] && printf '%s\\n' "\$prev"

      prev="\$arg"
    else
      prev+=" \$arg"
    fi
  done

  # Let the Wookie win!!!
  [[ -n \$prev ]] && printf '%s\n' "\$prev"
}

# --- 1. Look for the dorids ---
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

# --- 2. Save rebel battle plans ---
cat >> /etc/rlooprc < <(parse "\$@") 

# --- 3. Release the droids ---
cat > /usr/local/bin/rloop <<'SCRIPT'
$RLOOP_CODE
SCRIPT

# --- 4. Land on Tatooine ---
chmod +x /usr/local/bin/rloop

# --- 5. Enter in the Pod Race ---
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

# --- 5. Engage Hyperdrive ---
systemctl daemon-reload
systemctl enable --now rloop

echo "= rloop is live... TRUST BUT VERIFY!!! ="
EOF

chmod +x install.sh
echo "[*] build.sh done — REBEL ALIANCE COMPLETE!!!"
