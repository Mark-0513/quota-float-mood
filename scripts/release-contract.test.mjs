import assert from "node:assert/strict";
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const json = (path) => JSON.parse(read(path));

test("uses the Quota Float Mood product identity", () => {
  const pkg = json("package.json");
  const tauri = json("src-tauri/tauri.conf.json");
  assert.equal(pkg.name, "quota-float-mood");
  assert.equal(pkg.version, "0.2.0");
  assert.equal(tauri.productName, "Quota Float Mood");
  assert.equal(tauri.version, "0.2.0");
  assert.equal(tauri.identifier, "com.mark0513.quotafloatmood");
});

test("uses only the Mark-0513 release channel", () => {
  const releasesUrl = "https://github.com/Mark-0513/quota-float-mood/releases";
  const appUpdate = read("src/lib/appUpdate.ts");
  const readme = read("README.md");
  const sourceCapabilities = json("src-tauri/capabilities/default.json");
  const generatedCapabilities = json("src-tauri/gen/schemas/capabilities.json");
  const operationalFiles = [
    appUpdate,
    read("src-tauri/capabilities/default.json"),
    read("src-tauri/gen/schemas/capabilities.json"),
    read("src-tauri/tauri.conf.json"),
    read(".github/workflows/release.yml"),
  ].join("\n");
  assert.match(operationalFiles, /Mark-0513\/quota-float-mood/);
  assert.doesNotMatch(operationalFiles, /change-42-yhmm\/quota-float\/releases/);
  assert.ok(appUpdate.includes(`RELEASE_URL = "${releasesUrl}"`));
  assert.ok(readme.includes(`[👉 下载最新版](${releasesUrl})`));
  assert.doesNotMatch(`${appUpdate}\n${readme}`, /releases\/latest/);

  const expectedScope = [
    { url: releasesUrl },
    { url: `${releasesUrl}/*` },
  ];
  const sourceOpener = sourceCapabilities.permissions.find(
    (permission) => permission.identifier === "opener:allow-open-url",
  );
  const generatedOpener = generatedCapabilities.default.permissions.find(
    (permission) => permission.identifier === "opener:allow-open-url",
  );
  assert.deepEqual(sourceOpener.allow, expectedScope);
  assert.deepEqual(generatedOpener.allow, expectedScope);
});

test("preserves upstream contributor attribution", () => {
  const cargo = read("src-tauri/Cargo.toml");
  const tauri = json("src-tauri/tauri.conf.json");
  assert.match(cargo, /authors = \["Quota Float contributors and Mark-0513 contributors"\]/);
  assert.equal(tauri.bundle.copyright, "Copyright Quota Float contributors and Mark-0513 contributors");
});

test("keeps host and widget identities isolated from upstream", () => {
  const project = read("macos-signing/project.yml");
  const signingHostInfo = read("macos-signing/SigningHost/Info.plist");
  const widgetInfo = read("src-macos-widget/Info.plist");
  assert.match(project, /PRODUCT_BUNDLE_IDENTIFIER: com\.mark0513\.quotafloatmood$/m);
  assert.match(project, /PRODUCT_BUNDLE_IDENTIFIER: com\.mark0513\.quotafloatmood\.widget$/m);
  assert.match(project, /PRODUCT_NAME: Quota Float Mood$/m);
  assert.match(project, /MARKETING_VERSION: 0\.2\.0$/m);
  assert.match(project, /CURRENT_PROJECT_VERSION: 0\.2\.0$/m);
  assert.match(signingHostInfo, /<key>CFBundleVersion<\/key>\s*<string>0\.2\.0<\/string>/);
  assert.match(widgetInfo, /<key>CFBundleVersion<\/key>\s*<string>0\.2\.0<\/string>/);
});

test("requires macOS 14 for the Tauri host app", () => {
  const tauri = json("src-tauri/tauri.conf.json");
  assert.equal(tauri.bundle.macOS?.minimumSystemVersion, "14.0");
});

test("publishes one documented universal DMG", () => {
  const readme = read("README.md");
  assert.match(readme, /Quota-Float-Mood-v0\.2\.0-macOS-Universal\.dmg/);
  assert.match(readme, /macOS 14/);
  assert.match(readme, /Star/);
  assert.match(readme, /完全免费/);
  assert.match(readme, /是否支持完全自愿/);
  assert.match(readme, /Mark-0513/);
  assert.match(readme, /v0\.2\.0.*未签名\/ad-hoc beta/);
  assert.match(readme, /Control\/右键点击.*打开.*打开/);
  assert.match(readme, /系统设置.*隐私与安全性.*Open Anyway/);
  assert.match(readme, /change-42-yhmm\/quota-float/);
  assert.ok(existsSync(new URL("../docs/images/wechat-support.jpg", import.meta.url)));
  assert.match(read("NOTICE.md"), /Based on Quota Float/);
  assert.match(read("NOTICE.md"), /MIT License/);
});

test("publishes the documented macOS prerelease workflow", () => {
  const releaseWorkflow = read(".github/workflows/release.yml");
  assert.match(releaseWorkflow, /scripts\/build-macos-distribution\.sh/);
  assert.match(releaseWorkflow, /prerelease: true/);
  assert.match(releaseWorkflow, /\$\{\{ steps\.release_metadata\.outputs\.dmg_path \}\}/);
  assert.match(releaseWorkflow, /\$\{\{ steps\.release_metadata\.outputs\.checksum_path \}\}/);
});

test("installs official Tauri Linux prerequisites before Rust tests", () => {
  const ciWorkflow = read(".github/workflows/ci.yml");
  assert.match(ciWorkflow, /DEBIAN_FRONTEND=noninteractive apt-get update/);
  assert.match(ciWorkflow, /DEBIAN_FRONTEND=noninteractive apt-get install -y[\s\S]*build-essential[\s\S]*curl[\s\S]*wget[\s\S]*file[\s\S]*zsh[\s\S]*libxdo-dev[\s\S]*libssl-dev[\s\S]*libayatana-appindicator3-dev[\s\S]*librsvg2-dev[\s\S]*libwebkit2gtk-4\.1-dev/);
  assert.ok(ciWorkflow.indexOf("apt-get install") < ciWorkflow.indexOf("cargo test --manifest-path src-tauri/Cargo.toml"));
});

test("fails closed when the release tag, version, repository, or assets do not match", () => {
  const releaseWorkflow = read(".github/workflows/release.yml");
  assert.match(releaseWorkflow, /if: github\.repository == 'Mark-0513\/quota-float-mood'/);
  assert.match(releaseWorkflow, /id: release_metadata/);
  assert.match(releaseWorkflow, /VERSION="\$\(node -p "require\('\.\/package\.json'\)\.version"\)"/);
  assert.match(releaseWorkflow, /EXPECTED_TAG="v\$\{VERSION\}"/);
  assert.match(releaseWorkflow, /\[\[ "\$TAG_NAME" == "\$EXPECTED_TAG" \]\]/);
  assert.match(releaseWorkflow, /DMG_NAME="Quota-Float-Mood-v\$\{VERSION\}-macOS-Universal\.dmg"/);
  assert.match(releaseWorkflow, /fail_on_unmatched_files: true/);
  assert.match(releaseWorkflow, /overwrite_files: false/);
  assert.doesNotMatch(releaseWorkflow, /Quota Float Mood v0\.2\.0/);
  assert.doesNotMatch(releaseWorkflow, /Quota-Float-Mood-v0\.2\.0-macOS-Universal\.dmg/);
});

test("requires an installed and signed-in Codex Desktop in release notes", () => {
  const releaseTemplate = read("docs/RELEASE_TEMPLATE.md");
  assert.match(releaseTemplate, /已安装并登录 Codex Desktop/);
});

test("builds the documented universal DMG", () => {
  const script = read("scripts/build-macos-distribution.sh");
  const embedScript = read("scripts/embed-macos-widget.sh");
  assert.match(script, /Quota-Float-Mood-v\$\{VERSION\}-macOS-Universal\.dmg/);
  assert.match(script, /arm64/);
  assert.match(script, /x86_64/);
  assert.match(script, /codesign --verify --deep --strict/);
  assert.match(script, /shasum -a 256/);
  assert.ok((script.match(/CODE_SIGNING_REQUIRED=NO/g) ?? []).length >= 2);
  assert.match(script, /GENERATE_INFOPLIST_FILE=YES/);
  assert.match(script, /xcodebuild \\\n  -quiet/);
  assert.match(script, /build-for-testing/);
  assert.match(script, /xcrun xctest/);
  assert.match(script, /Executed 31 tests, with 0 failures/);
  assert.match(script, /rustup which cargo/);
  assert.match(script, /rustup target list --installed/);
  assert.match(embedScript, /EmbeddedBinaryValidationUtility/);
  assert.match(embedScript, /CFBundleVersion/);
  assert.match(embedScript, /-info-plist-path/);
  assert.match(embedScript, /-parent-bundle-path/);
});

test("fails closed before recursive cleanup when release is a symlink", () => {
  const fixtureRoot = mkdtempSync(join(tmpdir(), "quota-float-release-safety-"));
  const repository = join(fixtureRoot, "repository");
  const externalRelease = join(fixtureRoot, "external-release");
  const sentinel = join(externalRelease, "build", "must-survive.txt");

  try {
    mkdirSync(join(repository, "scripts"), { recursive: true });
    mkdirSync(join(repository, "src-tauri"), { recursive: true });
    mkdirSync(join(externalRelease, "build"), { recursive: true });
    cpSync(new URL("./build-macos-distribution.sh", import.meta.url), join(repository, "scripts", "build-macos-distribution.sh"));
    writeFileSync(join(repository, "package.json"), '{"version":"0.2.0"}\n');
    writeFileSync(join(repository, "src-tauri", "tauri.conf.json"), '{"version":"0.2.0"}\n');
    writeFileSync(sentinel, "external contents must survive\n");
    symlinkSync(externalRelease, join(repository, "release"), "dir");

    const result = spawnSync("zsh", [join(repository, "scripts", "build-macos-distribution.sh")], {
      encoding: "utf8",
      env: { ...process.env, SIGN_IDENTITY: "-", NOTARIZE: "0" },
    });

    assert.notEqual(result.status, 0);
    assert.match(`${result.stdout}\n${result.stderr}`, /symlink/i);
    assert.equal(existsSync(sentinel), true, "external release contents were deleted");
  } finally {
    rmSync(fixtureRoot, { force: true, recursive: true });
  }
});

test("validates physical build containment before recursive cleanup", () => {
  const script = read("scripts/build-macos-distribution.sh");
  assert.match(script, /\[\[ ! -L "\$RELEASE_DIR" \]\]/);
  assert.match(script, /\[\[ ! -L "\$BUILD_DIR" \]\]/);
  assert.match(script, /pwd -P/);
  assert.match(script, /assert_safe_build_dir/);
  assert.ok(script.indexOf("\nassert_safe_build_dir\n") < script.indexOf('rm -rf "$BUILD_DIR"'));
});

test("confines all operational build outputs to release/build", () => {
  const script = read("scripts/build-macos-distribution.sh");
  const viteConfig = read("vite.config.ts");
  const xcodeProject = read("macos-signing/project.yml");
  assert.match(script, /export CARGO_TARGET_DIR="\$BUILD_DIR\/cargo-target"/);
  assert.match(script, /FRONTEND_DIST="\$BUILD_DIR\/frontend-dist"/);
  assert.match(script, /export QUOTA_FLOAT_FRONTEND_DIST="\$FRONTEND_DIST"/);
  assert.match(script, /TAURI_BUILD_CONFIG/);
  assert.match(viteConfig, /process\.env\.QUOTA_FLOAT_FRONTEND_DIST/);
  assert.match(script, /xcodegen generate[\s\S]*--project "\$XCODE_PROJECT_DIR"/);
  assert.match(script, /mkdir -p "\$XCODE_PROJECT_DIR"/);
  assert.ok(script.indexOf('mkdir -p "$XCODE_PROJECT_DIR"') < script.indexOf("xcodegen generate"));
  assert.match(script, /--project-root "\$ROOT_DIR\/macos-signing"/);
  assert.ok((script.match(/QUOTA_FLOAT_SOURCE_ROOT="\$ROOT_DIR"/g) ?? []).length >= 2);
  assert.match(xcodeProject, /QUOTA_FLOAT_SOURCE_ROOT: \$\(PROJECT_DIR\)\/\.\.$/m);
  assert.match(xcodeProject, /INFOPLIST_FILE: \$\(QUOTA_FLOAT_SOURCE_ROOT\)\/src-macos-widget\/Info\.plist/);
  assert.match(xcodeProject, /CODE_SIGN_ENTITLEMENTS: \$\(QUOTA_FLOAT_SOURCE_ROOT\)\/src-macos-widget\/QuotaFloatWidget\.entitlements/);
  assert.doesNotMatch(script, /\$ROOT_DIR\/src-tauri\/target/);
  assert.doesNotMatch(script, /macos-signing\/QuotaFloatMoodSigning\.xcodeproj/);
  assert.doesNotMatch(script, /\$ROOT_DIR\/dist/);
});
