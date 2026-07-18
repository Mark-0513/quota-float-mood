#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  print -u2 "usage: $0 /path/to/Quota\\ Float\\ Mood.app <-|Developer ID Application identity>"
  exit 2
fi

APP_PATH="$1"
SIGN_IDENTITY="$2"
ROOT_DIR="${0:A:h:h}"
SOURCE_DIR="$ROOT_DIR/src-macos-widget"
BUILT_EXTENSION_PATH="${BUILT_EXTENSION_PATH:-$ROOT_DIR/release/build/widget-derived-data/Build/Products/Release/Quota Float Mood Widget.appex}"
EXTENSION_PATH="$APP_PATH/Contents/PlugIns/Quota Float Mood Widget.appex"

[[ -d "$APP_PATH" ]] || { print -u2 "app bundle not found: $APP_PATH"; exit 3; }
[[ -d "$BUILT_EXTENSION_PATH" ]] || {
  print -u2 "built widget extension not found: $BUILT_EXTENSION_PATH"
  exit 4
}
[[ ! -e "$EXTENSION_PATH" ]] || {
  print -u2 "target widget extension already exists: $EXTENSION_PATH"
  print -u2 "move it to a recoverable backup path before embedding"
  exit 5
}
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  [[ "$SIGN_IDENTITY" == "Developer ID Application:"* ]] || {
    print -u2 "identity must begin with 'Developer ID Application:'"
    exit 6
  }
  IDENTITY_LINE="$(security find-identity -v -p codesigning | grep -F -- "$SIGN_IDENTITY" | head -n 1 || true)"
  [[ -n "$IDENTITY_LINE" ]] || {
    print -u2 "Developer ID Application identity not found"
    exit 6
  }
fi

mkdir -p "$APP_PATH/Contents/PlugIns"
ditto "$BUILT_EXTENSION_PATH" "$EXTENSION_PATH"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --timestamp=none --options runtime \
    --entitlements "$SOURCE_DIR/QuotaFloatWidget.entitlements" \
    --sign - "$EXTENSION_PATH"
  codesign --force --timestamp=none --options runtime \
    --sign - "$APP_PATH"
else
  codesign --force --timestamp --options runtime \
    --entitlements "$SOURCE_DIR/QuotaFloatWidget.entitlements" \
    --sign "$SIGN_IDENTITY" "$EXTENSION_PATH"
  codesign --force --timestamp --options runtime \
    --sign "$SIGN_IDENTITY" "$APP_PATH"
fi

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  print "Signing mode: ad-hoc"
else
  print "Signing identity: $IDENTITY_LINE"
fi
print "Embedded and signed: $EXTENSION_PATH"
