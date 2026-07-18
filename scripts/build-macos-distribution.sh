#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
RELEASE_DIR="$ROOT_DIR/release"
BUILD_DIR="$RELEASE_DIR/build"
FRONTEND_DIST="$BUILD_DIR/frontend-dist"
XCODE_PROJECT_DIR="$BUILD_DIR/xcode-project"
XCODE_PROJECT="$XCODE_PROJECT_DIR/QuotaFloatMoodSigning.xcodeproj"
WIDGET_DERIVED_DATA="$BUILD_DIR/widget-derived-data"
WIDGET_TEST_DERIVED_DATA="$BUILD_DIR/widget-test-derived-data"
WIDGET_TEST_BUNDLE="$WIDGET_TEST_DERIVED_DATA/Build/Products/Debug/QuotaFloatMoodWidgetTests.xctest"
DMG_STAGE_DIR="$BUILD_DIR/dmg-root"
APP_NAME="Quota Float Mood"
EXTENSION_NAME="Quota Float Mood Widget"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
NOTARIZE="${NOTARIZE:-0}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

fail() {
  print -u2 -- "error: $*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

verify_universal() {
  local binary_path="$1"
  local architectures
  architectures="$(lipo -archs "$binary_path")"
  [[ " $architectures " == *" arm64 "* ]] || fail "arm64 slice missing: $binary_path ($architectures)"
  [[ " $architectures " == *" x86_64 "* ]] || fail "x86_64 slice missing: $binary_path ($architectures)"
  print -- "Universal slices: $binary_path -> $architectures"
}

assert_safe_build_dir() {
  local repo_physical
  local release_physical
  local build_physical

  [[ ! -L "$RELEASE_DIR" ]] || fail "release directory is a symlink: $RELEASE_DIR"
  [[ ! -L "$BUILD_DIR" ]] || fail "build directory is a symlink: $BUILD_DIR"

  repo_physical="$(cd "$ROOT_DIR" && pwd -P)"
  mkdir -p "$RELEASE_DIR"
  [[ ! -L "$RELEASE_DIR" ]] || fail "release directory became a symlink: $RELEASE_DIR"
  release_physical="$(cd "$RELEASE_DIR" && pwd -P)"
  [[ "$release_physical" == "$repo_physical/release" ]] || \
    fail "physical release directory escapes repository: $release_physical"

  mkdir -p "$BUILD_DIR"
  [[ ! -L "$BUILD_DIR" ]] || fail "build directory became a symlink: $BUILD_DIR"
  build_physical="$(cd "$BUILD_DIR" && pwd -P)"
  [[ "$build_physical" == "$repo_physical/release/build" ]] || \
    fail "physical build directory escapes repository: $build_physical"
  [[ "$build_physical" == "$repo_physical/"* ]] || \
    fail "physical build directory is outside repository: $build_physical"
}

assert_safe_build_dir

if ! command -v rustup >/dev/null 2>&1; then
  for rustup_bin_dir in /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin; do
    if [[ -x "$rustup_bin_dir/rustup" ]]; then
      export PATH="$rustup_bin_dir:$PATH"
      break
    fi
  done
fi

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS is required"
for tool in node npm rustup cargo xcodegen xcodebuild hdiutil codesign lipo xcrun ditto shasum spctl plutil; do
  require_command "$tool"
done

export RUSTUP_TOOLCHAIN=stable
RUSTUP_CARGO="$(rustup which cargo)" || fail "rustup stable cargo is unavailable"
RUSTUP_RUSTC="$(rustup which rustc)" || fail "rustup stable rustc is unavailable"
RUST_TOOLCHAIN_BIN="${RUSTUP_CARGO:h}"
[[ "$RUSTUP_RUSTC" == "$RUST_TOOLCHAIN_BIN/rustc" ]] || fail "rustup cargo and rustc use different toolchains"
export PATH="$RUST_TOOLCHAIN_BIN:$PATH"
[[ "$(command -v cargo)" == "$RUSTUP_CARGO" ]] || fail "cargo did not resolve to the rustup toolchain"

[[ "$NOTARIZE" == "0" || "$NOTARIZE" == "1" ]] || fail "NOTARIZE must be 0 or 1"
if [[ "$SIGN_IDENTITY" != "-" && "$SIGN_IDENTITY" != "Developer ID Application:"* ]]; then
  fail "SIGN_IDENTITY must be - or begin with 'Developer ID Application:'"
fi
if [[ "$NOTARIZE" == "1" ]]; then
  [[ "$SIGN_IDENTITY" == "Developer ID Application:"* ]] || \
    fail "NOTARIZE=1 requires a Developer ID Application identity"
  [[ -n "$NOTARY_PROFILE" ]] || \
    fail "NOTARIZE=1 requires a notarytool keychain profile in NOTARY_PROFILE"
fi

cd "$ROOT_DIR"
VERSION="$(node -p "require('./package.json').version")"
TAURI_VERSION="$(node -p "require('./src-tauri/tauri.conf.json').version")"
[[ "$VERSION" == "$TAURI_VERSION" ]] || fail "package and Tauri versions differ: $VERSION != $TAURI_VERSION"

DMG_NAME="Quota-Float-Mood-v${VERSION}-macOS-Universal.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"
export CARGO_TARGET_DIR="$BUILD_DIR/cargo-target"
export QUOTA_FLOAT_FRONTEND_DIST="$FRONTEND_DIST"
TAURI_BUILD_CONFIG="$(node -e 'process.stdout.write(JSON.stringify({ build: { frontendDist: process.env.QUOTA_FLOAT_FRONTEND_DIST } }))')"
TAURI_APP="$CARGO_TARGET_DIR/universal-apple-darwin/release/bundle/macos/$APP_NAME.app"
PACKAGED_APP="$BUILD_DIR/$APP_NAME.app"
WIDGET_APP="$WIDGET_DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
BUILT_EXTENSION="$WIDGET_DERIVED_DATA/Build/Products/Release/$EXTENSION_NAME.appex"
PACKAGED_EXTENSION="$PACKAGED_APP/Contents/PlugIns/$EXTENSION_NAME.appex"
HOST_BINARY="$PACKAGED_APP/Contents/MacOS/quota-float-mood"
EXTENSION_BINARY="$PACKAGED_EXTENSION/Contents/MacOS/$EXTENSION_NAME"

[[ "$BUILD_DIR" == "$ROOT_DIR/release/build" ]] || fail "refusing unsafe build directory: $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
rm -f "$DMG_PATH" "$CHECKSUM_PATH"

print -- "==> Installing Rust universal macOS targets"
rustup target add aarch64-apple-darwin x86_64-apple-darwin
INSTALLED_RUST_TARGETS="$(rustup target list --installed)"
for rust_target in aarch64-apple-darwin x86_64-apple-darwin; do
  [[ "$INSTALLED_RUST_TARGETS" == *"$rust_target"* ]] || fail "Rust target is not installed: $rust_target"
done
print -- "Rust cargo: $RUSTUP_CARGO"
print -- "Rust compiler: $RUSTUP_RUSTC"

print -- "==> Running npm tests"
npm test

print -- "==> Running Rust tests"
cargo test --manifest-path src-tauri/Cargo.toml

print -- "==> Generating the WidgetKit Xcode project"
mkdir -p "$XCODE_PROJECT_DIR"
xcodegen generate \
  --spec "$ROOT_DIR/macos-signing/project.yml" \
  --project "$XCODE_PROJECT_DIR" \
  --project-root "$ROOT_DIR/macos-signing"

print -- "==> Building the WidgetKit test bundle"
xcodebuild \
  -quiet \
  -project "$XCODE_PROJECT" \
  -scheme QuotaFloatMoodSigningHost \
  -configuration Debug \
  -derivedDataPath "$WIDGET_TEST_DERIVED_DATA" \
  build-for-testing \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  GENERATE_INFOPLIST_FILE=YES \
  QUOTA_FLOAT_SOURCE_ROOT="$ROOT_DIR"
[[ -d "$WIDGET_TEST_BUNDLE" ]] || fail "WidgetKit test bundle not found: $WIDGET_TEST_BUNDLE"
[[ -x "$WIDGET_TEST_BUNDLE/Contents/MacOS/QuotaFloatMoodWidgetTests" ]] || \
  fail "WidgetKit test executable not found"
plutil -lint "$WIDGET_TEST_BUNDLE/Contents/Info.plist"

print -- "==> Running WidgetKit tests"
WIDGET_TEST_OUTPUT="$(xcrun xctest "$WIDGET_TEST_BUNDLE" 2>&1)"
print -- "$WIDGET_TEST_OUTPUT"
[[ "$WIDGET_TEST_OUTPUT" == *"Test Suite 'All tests' passed"* ]] || \
  fail "WidgetKit all-tests suite did not pass"
[[ "$WIDGET_TEST_OUTPUT" == *"Executed 31 tests, with 0 failures"* ]] || \
  fail "WidgetKit test count changed or failures occurred"

print -- "==> Building the universal Tauri app"
npm run tauri -- build --target universal-apple-darwin --bundles app --config "$TAURI_BUILD_CONFIG"
[[ -d "$TAURI_APP" ]] || fail "Tauri app not found at inspected output path: $TAURI_APP"

print -- "==> Building the universal WidgetKit host and extension"
xcodebuild \
  -project "$XCODE_PROJECT" \
  -scheme QuotaFloatMoodSigningHost \
  -configuration Release \
  -derivedDataPath "$WIDGET_DERIVED_DATA" \
  build \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  QUOTA_FLOAT_SOURCE_ROOT="$ROOT_DIR"
[[ -d "$WIDGET_APP" ]] || fail "WidgetKit host not found at inspected output path: $WIDGET_APP"
[[ -d "$BUILT_EXTENSION" ]] || fail "WidgetKit extension not found at inspected output path: $BUILT_EXTENSION"

ditto "$TAURI_APP" "$PACKAGED_APP"
BUILT_EXTENSION_PATH="$BUILT_EXTENSION" \
  "$ROOT_DIR/scripts/embed-macos-widget.sh" "$PACKAGED_APP" "$SIGN_IDENTITY"

[[ -f "$HOST_BINARY" ]] || fail "Tauri executable not found: $HOST_BINARY"
[[ -f "$EXTENSION_BINARY" ]] || fail "Widget executable not found: $EXTENSION_BINARY"
verify_universal "$HOST_BINARY"
verify_universal "$EXTENSION_BINARY"
codesign --verify --deep --strict --verbose=2 "$PACKAGED_APP"

mkdir -p "$DMG_STAGE_DIR"
ditto "$PACKAGED_APP" "$DMG_STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE_DIR/Applications"

print -- "==> Creating $DMG_NAME"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  print -- "Artifact status: unsigned/ad-hoc beta; not notarized; Gatekeeper acceptance is not claimed."
elif [[ "$NOTARIZE" == "0" ]]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
  print -- "Artifact status: Developer ID signed; not notarized; Gatekeeper acceptance is not claimed."
else
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
  print -- "==> Submitting for Apple notarization"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH"
  print -- "Artifact status: Developer ID signed and notarized."
fi

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
)

print -- "DMG: $DMG_PATH"
print -- "SHA-256: $CHECKSUM_PATH"
