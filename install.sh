#!/bin/sh
# Session Limits — companion installer for Codex.
#
#   curl -fsSL https://raw.githubusercontent.com/minobots/session-limit-tracker/main/scripts/install.sh | sh
#
# Downloads the `sessiond` helper, installs it as a login agent (so it keeps
# serving), and prints this machine's pairing QR. Re-run any time to reprint it.
# Reads Codex usage from your logged-in `codex` CLI. Nothing leaves this Mac
# except the requests `codex` already makes.
set -eu

REPO="minobots/session-limits-companion"
DEST="$HOME/.session-limit-tracker"
BIN="$DEST/bin/sessiond"
PLIST="$HOME/Library/LaunchAgents/com.sessionlimit.sessiond.plist"
LABEL="com.sessionlimit.sessiond"

[ "$(uname -s)" = "Darwin" ] || { echo "This installer is macOS-only." >&2; exit 1; }

arch=$(uname -m)
case "$arch" in
  arm64) assets="sessiond-macos-arm64 sessiond-macos-x64" ;;  # x64 runs via Rosetta
  x86_64) assets="sessiond-macos-x64" ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

mkdir -p "$DEST/bin"
ok=""
for asset in $assets; do
  url="https://github.com/$REPO/releases/latest/download/$asset"
  echo "Downloading $asset…"
  if curl -fsSL "$url" -o "$BIN.tmp"; then ok=1; break; fi
done
[ -n "$ok" ] || {
  echo "Download failed. Check for a release at" >&2
  echo "  https://github.com/$REPO/releases/latest" >&2
  exit 1
}
mv "$BIN.tmp" "$BIN"
chmod +x "$BIN"
xattr -d com.apple.quarantine "$BIN" 2>/dev/null || true

# Login agent so it keeps running (and restarts on crash / login).
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array>
    <string>$BIN</string><string>--lan</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$DEST/sessiond.log</string>
  <key>StandardErrorPath</key><string>$DEST/sessiond.log</string>
</dict></plist>
PLIST

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
sleep 1

echo
"$BIN" --pair
