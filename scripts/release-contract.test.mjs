import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
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
  const operationalFiles = [
    "src/lib/appUpdate.ts",
    "src-tauri/capabilities/default.json",
    "src-tauri/gen/schemas/capabilities.json",
    "src-tauri/tauri.conf.json",
    ".github/workflows/release.yml",
  ].map(read).join("\n");
  assert.match(operationalFiles, /Mark-0513\/quota-float-mood/);
  assert.doesNotMatch(operationalFiles, /change-42-yhmm\/quota-float\/releases/);
});

test("preserves upstream contributor attribution", () => {
  const cargo = read("src-tauri/Cargo.toml");
  const tauri = json("src-tauri/tauri.conf.json");
  assert.match(cargo, /authors = \["Quota Float contributors and Mark-0513 contributors"\]/);
  assert.equal(tauri.bundle.copyright, "Copyright Quota Float contributors and Mark-0513 contributors");
});

test("keeps host and widget identities isolated from upstream", () => {
  const project = read("macos-signing/project.yml");
  assert.match(project, /PRODUCT_BUNDLE_IDENTIFIER: com\.mark0513\.quotafloatmood$/m);
  assert.match(project, /PRODUCT_BUNDLE_IDENTIFIER: com\.mark0513\.quotafloatmood\.widget$/m);
  assert.match(project, /PRODUCT_NAME: Quota Float Mood$/m);
  assert.match(project, /MARKETING_VERSION: 0\.2\.0$/m);
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

test("builds the documented universal DMG", () => {
  const script = read("scripts/build-macos-distribution.sh");
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
});
