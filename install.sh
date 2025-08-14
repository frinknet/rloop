#!/bin/bash
set -e

echo
echo "= rloop installer — May the Ports Be With You. ="
echo

# Use the source Luke
parse() {
  local prev=

  # Search your feelings
  for arg in "$@"; do
    # These are the droids we are looking for
    if [[ "$arg" =~ [^0-9:] ]]; then
      [[ -n "$prev" ]] && printf '%s\n' "$prev"

      prev="$arg"
    else
      prev+=" $arg"
    fi
  done

  # Let the Wookie win!!!
  [[ -n $prev ]] && printf '%s\n' "$prev"
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
cat > /etc/rlooprc < <(parse "$@") 

# --- 3. Release the droids ---
cat > /usr/local/bin/rloop <<'SCRIPT'
#!/bin/bash
# © 2025 FRINKnet & Friends – MIT LICENSE
#  rloop — May the Ports Be With You!!!

export TEST=0
export VER="1.2"
export BIN="${0##*/}"
export PIDS=()

set -m  # Enable job control
trap "kill -- -$$" EXIT

# Trust. But verify...
if [[ "$1" == "--test" ]]; then
  TEST=1

  shift
fi

# For those who don't understand the Force
help() {
  echo
  echo " © 2025 FRINKnet & Friends – MIT LICENSE"
  echo "  rloop — May the Ports Be With You!!!"
  echo
  echo "  Usage: $0 [--test] user@server port[:remote] …"
  echo

  exit 1
}

# Use the source Luke
parse() {
  local prev=

  # Search your feelings
  for arg in "$@"; do
    # Bring balance to the Force
    if [[ "$arg" =~ [^0-9:] ]]; then
      [[ -n "$prev" ]] && printf '%s\n' "$prev"

      prev="$arg"
    else
      prev+=" $arg"
    fi
  done

  # Let the Wookie win!!!
  [[ -n $prev ]] && printf '%s\n' "$prev"
}

# Almost there... Almost there...
mapping() {
  local mapping left right tunnel_args=

  # The odds of navigating are 3720 to 1
  for mapping in "$@"; do
    left="${mapping%%:*}"
    right="${mapping##*:}"

    # Stupid users need to be warned
    if [[ -z $left || -z $right ]]; then
      echo "Error: mapping '$mapping' is malformed... Oh the insanity of it all!" >&2

      exit 3
    fi

    # May the wrath of Yoda rain down!
    if ! [[ $left =~ ^[0-9]+$ && $right =~ ^[0-9]+$ ]]; then
      echo "Error: mapping '$mapping' contains non-numeric ports… RAGE QUITTING!" >&2

      exit 4
    fi

    # New fluent in over &m forms of communication
    tunnel_args+=" -R 0.0.0.0:${right}:localhost:${left}"
  done

  # now fluent in over 7m form of communication
  echo "$tunnel_args"
}

# Take us to Coruscant!!!
connect() {
  local tunnel_args server ports err

  server="$1"; shift
  ports=( "$@" )

  # Guardrails so you don’t tunnel into a reverse Death Star
  if [[ "$server" =~ ^[0-9]+$ || "$server" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Error: '$server' looks like a port or rogue asteroid." >&2

    exit 2
  fi

  # Prepare to jump to hyperspace
  tunnel_args="$(mapping "${ports[@]}")"

  # if the padowans come to play...
  if (( TEST )); then
    echo
    echo "TESTING: autossh -M0 -N -o ServerAliveInterval=2 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes $server$tunnel_args"
    echo

    autossh -M0 -N \
      -o "ServerAliveInterval=2" -o "ServerAliveCountMax=3" \
      -o "ExitOnForwardFailure=yes" "$server" $tunnel_args

    err=$?

    echo

    if (( err == 0 )); then
      echo "  ...Test complete. No hull breaches detected."
      echo
      return
    else
      echo "  POODOO!!! - Banthas detected... - exit $err" >&2
      echo
      exit $err
    fi
  fi

  (
    # Eternal tunnel loop
    while true; do
      # This should not fail
      autossh -M0 -N \
        -o "ServerAliveInterval=2" -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes" "$server" $tunnel_args

      # If it does wait two bits
      sleep 2

      # Go on like this FOREVER!!!
    done

    # Usa da boomba!!
  ) &

  # Me lika disa one!
  PIDS+=( $! )
}

# Are there Midi-Chlorians here?
if [ ! -t 0 ]; then
  mapfile -t lines
else
  mapfile -t lines < <(parse "$@")
fi

# The Jedi forbid aimless excess
if (( ${#lines[@]} == 0 )); then
  help
fi

# Reach out to the Force all around
for line in "${lines[@]}"; do
  read -r server rest <<< "$line"
  read -ra ports <<< "$rest"

  # Reach out to the fource all around
  connect "$server" "${ports[@]}"
done

# Patience is a virtue young padawan.
for pid in "${PIDS[@]}"; do
  wait "$pid"
done
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
