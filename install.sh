#!/bin/sh
# Session Limits -- companion installer for Codex.
#
#   curl -fsSL https://raw.githubusercontent.com/minobots/session-limits-companion/main/install.sh | sh
#
# What it does, and nothing else:
#   1. Downloads one small program, "sessiond" (~7 MB), to ~/.session-limit-tracker/bin
#   2. Sets it to run at login so it stays available
#   3. Prints a QR code to pair the Session Limits phone app with THIS Mac
#
# sessiond reads your Codex usage from your already-logged-in `codex` CLI and
# serves it on your local network to the app. It has no other network access.
# Source: https://github.com/minobots/session-limits-companion
set -eu

REPO="minobots/session-limits-companion"
DEST="$HOME/.session-limit-tracker"
BIN="$DEST/bin/sessiond"
PLIST="$HOME/Library/LaunchAgents/com.sessionlimit.sessiond.plist"
LABEL="com.sessionlimit.sessiond"

[ "$(uname -s)" = "Darwin" ] || { echo "This installer is macOS only." >&2; exit 1; }

arch=$(uname -m)
if [ "$arch" = "arm64" ]; then
  assets="sessiond-macos-arm64 sessiond-macos-x64"   # x64 runs under Rosetta
elif [ "$arch" = "x86_64" ]; then
  assets="sessiond-macos-x64"
else
  echo "Unsupported architecture: $arch" >&2
  exit 1
fi

mkdir -p "$DEST/bin"
downloaded=no
for a in $assets; do
  echo "Downloading $a ..."
  if curl -fsSL "https://github.com/$REPO/releases/latest/download/$a" -o "$BIN.tmp"; then
    downloaded=yes
    break
  fi
done
if [ "$downloaded" != yes ]; then
  echo "Download failed -- check https://github.com/$REPO/releases/latest" >&2
  exit 1
fi

mv "$BIN.tmp" "$BIN"
chmod +x "$BIN"
xattr -dr com.apple.quarantine "$BIN" 2>/dev/null || true

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

echo ""
"$BIN" --pair
