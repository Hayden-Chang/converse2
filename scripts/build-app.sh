#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Converse"
APP="$ROOT/build/$APP_NAME.app"
PKG="$ROOT/Packaging"
TMUX_SRC="${CONVERSE_TMUX_SRC:-/usr/local/bin/tmux}"

echo "==> Building release (SPM, via SSH-resolved deps)"
cd "$ROOT"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN" ]]; then echo "ERROR: release binary not found at $BIN" >&2; exit 1; fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/bin"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp "$PKG/Info.plist" "$APP/Contents/Info.plist"

if [[ -x "$TMUX_SRC" ]]; then
  cp "$TMUX_SRC" "$APP/Contents/Resources/bin/tmux"
  echo "    bundled tmux: $TMUX_SRC"
else
  echo "    WARN: tmux not found at $TMUX_SRC (set CONVERSE_TMUX_SRC); .app will fall back to system tmux" >&2
fi

if [[ "${1:-}" == "--sign-dev" ]]; then
  ENT="$PKG/Converse.entitlements"
  IDENTITY="${CONVERSE_SIGN_IDENTITY:-Developer ID Application}"
  echo "==> Hardened Runtime + signing with $IDENTITY"
  codesign --force --deep --options runtime --entitlements "$ENT" \
    --sign "$IDENTITY" "$APP"
  echo "==> Submitting for notarization (requires App Store Connect API key / Apple ID)"
  xcrun notarytool submit "$APP.zip" --keychain-profile "$NOTARY_PROFILE" --wait || \
    echo "    notarization skipped (needs NOTARY_PROFILE); see Packaging/RELEASE.md"
  xcrun stapler staple "$APP" || true
else
  echo "==> Ad-hoc signing (development only — Gatekeeper will not pass for distribution)"
  codesign --force --deep --sign - "$APP"
fi

echo "==> Done: $APP"
echo "    Run: open $APP   (dev)   |   Distribute: zip + notarize (see RELEASE.md)"
