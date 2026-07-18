#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  print -u2 "usage: $0 /path/to/Quota\\ Float.app <Apple Development identity>"
  exit 2
fi

APP_PATH="$1"
SIGN_IDENTITY="$2"
ROOT_DIR="${0:A:h:h}"
SOURCE_DIR="$ROOT_DIR/src-macos-widget"
BUILT_EXTENSION_PATH="$ROOT_DIR/macos-signing/DerivedDataUnsigned/Build/Products/Release/Quota Float.app/Contents/PlugIns/Quota Float Widget.appex"
EXTENSION_PATH="$APP_PATH/Contents/PlugIns/Quota Float Widget.appex"
IDENTITY_LINE="$(security find-identity -v -p codesigning | grep -F -- "$SIGN_IDENTITY" | head -n 1 || true)"

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
[[ "$IDENTITY_LINE" == *'"Apple Development:'* ]] || {
  print -u2 "valid Apple Development identity not found: $SIGN_IDENTITY"
  exit 6
}

mkdir -p "$APP_PATH/Contents/PlugIns"
ditto "$BUILT_EXTENSION_PATH" "$EXTENSION_PATH"

codesign --force --timestamp=none --options runtime \
  --entitlements "$SOURCE_DIR/QuotaFloatWidget.entitlements" \
  --sign "$SIGN_IDENTITY" "$EXTENSION_PATH"

codesign --force --timestamp=none --options runtime \
  --sign "$SIGN_IDENTITY" "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
print "Signing identity: $IDENTITY_LINE"
print "Embedded and signed: $EXTENSION_PATH"
