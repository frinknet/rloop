# rloop — MAY THE PORTS BE WITH YOU!!!

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

```bash
curl https://raw.githubusercontent.com/frinknet/rloop/refs/heads/main/install.sh | sudo bash -s user@host 25 53
```
1. Cat the installer to root bash (Read the source - I'm responsible...)
2. Saddly ports below 1000 need root authority which is usually what you want.
3. Enjoy the service and never look back.
4. If you need to reconfigure you can look at `/etc/rlooprc`
5. You can also update	to a new version doing the following...

```bash
curl https://raw.githubusercontent.com/frinknet/rloop/refs/heads/main/install.sh | sudo bash -s $(cat /etc/rlooprc)
```

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

MIT License - Share the Lemure love. The copyright info is in the code. PRs and FORKs welcome!!!!

***

Official docs:	
- autossh: Keeps tunnels alive, even through network tantrums.	
- systemd: Turns scripts into immortal daemons, provided you’re polite to root.  
- Bash: The shell. You already know.
