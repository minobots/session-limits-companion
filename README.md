# Session Limits — companion

A tiny helper (`sessiond`) that lets the **Session Limits** app show your
**Codex** usage. Codex/ChatGPT has no usage API, so a small process on the Mac
where you use `codex` reads the numbers from your logged-in CLI and serves them
to the app over your local network. Nothing else leaves the machine.

MiniMax, OpenCode Go and Claude don't need this — they connect directly in the
app.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/minobots/session-limits-companion/main/install.sh | sh
```

Downloads `sessiond`, installs it as a login agent, and prints a pairing QR.
In the app: **Settings → Companion app → Scan pairing code**. Re-run any time to
reprint the QR. The QR carries this machine's own address and a unique token —
every user pairs their own account.

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/com.sessionlimit.sessiond.plist
rm ~/Library/LaunchAgents/com.sessionlimit.sessiond.plist
rm -rf ~/.session-limit-tracker
```

## Build from source

The daemon source lives in the app repo; `scripts/build-daemon.sh` there
produces `dist/sessiond-<os>-<arch>`.
