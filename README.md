# rloop — Multi-Port SSH Tunnel Daemon

Ever wanted to sling a dozen ports through space-time with one command? rloop is your answer. It’s a single-script marvel: set up persistent, auto-reconnecting reverse SSH tunnels that forward any pile of ports (or local:remote combos) through autossh, with a systemd tailwind. All you need is a config file, a dash of ambition, and a knack for wrangling penguins.

## Features

- **Multi-port magic** — Map port:port or local:remote pairs, as many as your patience allows.
- **Config-driven or CLI mode** — Reads `/etc/rlooprc`, or just pass host and ports right in.
- **Systemd-integrated** — Run as a background service. Reboots? Network hiccups? rloop shrugs.
- **Auto-reconnect** — Handles disconnects like a caffeinated butler: always on call.
- **Portable** — Works on Alpine, AlmaLinux, Arch, Debian/Ubuntu, RHEL/CentOS. If it runs bash, it runs rloop.

## Usage

**Config File** (`/etc/rlooprc`):
```
user@host
53
25
993
8080:80
```

**Run via config:**
```bash
cat /etc/rlooprc | rloop
```

**Or direct from CLI:**
```bash
rloop root@cloud.example.com 53 25 993 8080:80
```

## Install

1. `curl -sSL https://you/your/install.sh | bash` (replace with real link, no funny business)
2. Answer the prompts: server, ports, mappings.
3. Enjoy the service and never look back.

## Systemd

- Service auto-starts and persists across reboots
- Check status:
  ```bash
  systemctl status rloop
  ```

## Notes

- Requires `autossh` (installer gets it for you)
- Local:remote mapping supported (`PORT` = `PORT:PORT`, or expand as `LOCAL:REMOTE`)
- Logs reconnections; if you see too many, your network needs more vitamins.

## License

Public domain. The code is yours. Abuse responsibly, preferably in the name of progress.

***

Official docs:	
- autossh: Keeps tunnels alive, even through network tantrums.	
- systemd: Turns scripts into immortal daemons, provided you’re polite to root.  
- Bash: The shell. You already know.
