# Quota Float Mood Open-Source Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish Quota Float Mood as a clearly attributed, free macOS 14+ GitHub fork with one universal DMG download, six small/medium emotional widget themes, a Star request, and Mark's optional WeChat support QR code.

**Architecture:** Keep the existing Tauri/React/Rust quota host and SwiftUI WidgetKit extension, but give the enhanced edition an independent product identity and release channel. A repository-level release contract test protects branding, URLs, attribution, and packaging; a macOS packaging script builds the universal host and extension, embeds and signs them together, then creates the DMG and checksum. GitHub remains connected to upstream as a fork, while Releases are controlled by `Mark-0513`.

**Tech Stack:** Tauri 2, React 19, TypeScript, Rust, SwiftUI, WidgetKit, XcodeGen, Xcode, zsh, Node test runner, GitHub Actions, GitHub CLI.

## Global Constraints

- Public repository: `Mark-0513/quota-float-mood`, forked from `change-42-yhmm/quota-float`.
- Product name: `Quota Float Mood`; initial enhanced version: `0.2.0` / tag `v0.2.0`.
- Main bundle ID: `com.mark0513.quotafloatmood`; widget bundle ID: `com.mark0513.quotafloatmood.widget`.
- Minimum supported macOS version: `14.0`; release architecture: universal `arm64` plus `x86_64`.
- Ordinary-user asset: `Quota-Float-Mood-v0.2.0-macOS-Universal.dmg` plus its SHA-256 file.
- Preserve the upstream MIT license and clearly distinguish upstream authorship from Mark's enhancements.
- The WeChat payment QR is optional support only and never gates functionality.
- Automatic updates must not trust the upstream signing key or release endpoint; use a manual link to Mark's Releases until a fork-owned updater chain exists.
- Never commit Apple certificates, private signing keys, Apple credentials, Codex credentials, GitHub tokens, or updater private keys.
- Do not claim notarization unless `spctl` accepts the exact public artifact.

---

### Task 1: Lock the Independent Product and Release Contract

**Files:**
- Create: `scripts/release-contract.test.mjs`
- Modify: `package.json`
- Modify: `package-lock.json`
- Modify: `src-tauri/Cargo.toml`
- Modify: `src-tauri/Cargo.lock`
- Modify: `src-tauri/tauri.conf.json`
- Modify: `src-tauri/capabilities/default.json`
- Modify: `src/lib/appUpdate.ts`
- Create: `src/lib/appUpdate.test.ts`
- Modify: `src-tauri/src/lib.rs`
- Modify: `src/lib/i18n.ts`
- Modify: `index.html`
- Modify: `macos-signing/project.yml`
- Modify: `macos-signing/SigningHost/Info.plist`
- Modify: `macos-signing/SigningHost/SigningHostApp.swift`
- Modify: `src-macos-widget/Info.plist`
- Modify: `src-macos-widget/Core/QuotaFormatter.swift`
- Modify: `src-macos-widget/Data/QuotaSnapshotStore.swift`
- Modify: `src-macos-widget-tests/QuotaFormatterTests.swift`
- Modify: `src-macos-widget-tests/QuotaSnapshotStoreTests.swift`

**Interfaces:**
- Consumes: Existing Tauri app configuration, XcodeGen project, release URL helper, and widget cache.
- Produces: Version `0.2.0`, fork-owned identifiers/URLs, `npm run test:release-contract`, and a manual release-page update path.

- [ ] **Step 1: Write the failing repository release-contract test**

Create `scripts/release-contract.test.mjs` with exact cross-file assertions:

```js
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
    "src-tauri/tauri.conf.json",
    ".github/workflows/release.yml",
  ].map(read).join("\n");
  assert.match(operationalFiles, /Mark-0513\/quota-float-mood/);
  assert.doesNotMatch(operationalFiles, /change-42-yhmm\/quota-float\/releases/);
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
  assert.match(readme, /change-42-yhmm\/quota-float/);
  assert.ok(existsSync(new URL("../docs/images/wechat-support.jpg", import.meta.url)));
});
```

- [ ] **Step 2: Run the contract test and verify RED**

Run:

```bash
node --test scripts/release-contract.test.mjs
```

Expected: FAIL because the package is still `quota-float@0.1.5`, the bundle IDs use `app.quotafloat`, operational URLs point upstream, and the support image is not yet in the repository.

- [ ] **Step 3: Write failing update-channel behavior tests**

Create `src/lib/appUpdate.test.ts`:

```ts
import { beforeEach, describe, expect, it, vi } from "vitest";
import { checkForAppUpdate, RELEASE_URL } from "./appUpdate";

describe("Quota Float Mood release channel", () => {
  beforeEach(() => vi.restoreAllMocks());

  it("points to the Mark-0513 latest release", () => {
    expect(RELEASE_URL).toBe("https://github.com/Mark-0513/quota-float-mood/releases/latest");
  });

  it("does nothing for automatic checks until a fork-owned updater exists", async () => {
    const status = vi.fn();
    const open = vi.spyOn(window, "open");
    await checkForAppUpdate("zh", messages, status, false);
    expect(status).not.toHaveBeenCalled();
    expect(open).not.toHaveBeenCalled();
  });
});

const messages = {
  checking: "checking",
  current: "current",
  downloading: (version: string) => version,
  installing: "installing",
  availableWindows: (version: string) => version,
  availableMac: (version: string) => version,
  failed: "failed",
};
```

- [ ] **Step 4: Run the update tests and verify RED**

Run:

```bash
npx vitest run src/lib/appUpdate.test.ts --configLoader native
```

Expected: FAIL because `RELEASE_URL` still points to the upstream repository and automatic checks still invoke the upstream updater.

- [ ] **Step 5: Apply the exact identity and version changes**

Use these values everywhere the corresponding production metadata appears:

```text
package name                 quota-float-mood
product/display name         Quota Float Mood
version                      0.2.0
main bundle ID               com.mark0513.quotafloatmood
widget bundle ID             com.mark0513.quotafloatmood.widget
widget cache key             com.mark0513.quotafloatmood.widget.last-successful-snapshot
release URL                  https://github.com/Mark-0513/quota-float-mood/releases/latest
release permission URL       https://github.com/Mark-0513/quota-float-mood/releases/*
Xcode project name           QuotaFloatMoodSigning
Xcode host target/scheme     QuotaFloatMoodSigningHost
Xcode widget target          QuotaFloatMoodWidget
```

Remove the Tauri updater endpoint/public key from `src-tauri/tauri.conf.json`, remove updater/process permissions that exist only for install-and-relaunch, and remove updater initialization from `src-tauri/src/lib.rs`. Implement `checkForAppUpdate` as a no-op for automatic checks and a direct call to `openReleasePage()` for manual checks. Keep failure reporting when opening the release page fails.

Add this package script:

```json
"test:release-contract": "node --test scripts/release-contract.test.mjs"
```

Update `package-lock.json` with:

```bash
npm install --package-lock-only --ignore-scripts
```

Update `Cargo.lock` with:

```bash
cargo check --manifest-path src-tauri/Cargo.toml
```

Regenerate the ignored Xcode project only for local validation:

```bash
xcodegen generate --spec macos-signing/project.yml --project macos-signing
```

- [ ] **Step 6: Run focused tests and verify GREEN**

Run:

```bash
node --test --test-name-pattern="uses the Quota|uses only|keeps host" scripts/release-contract.test.mjs
npx vitest run src/lib/appUpdate.test.ts --configLoader native
xcodebuild -project macos-signing/QuotaFloatSigning.xcodeproj -scheme QuotaFloatMoodSigningHost -configuration Debug -derivedDataPath macos-signing/DerivedDataReleaseBranding test CODE_SIGNING_ALLOWED=NO
```

Expected: the identity/channel contract subset passes, Vitest passes, and all WidgetKit unit tests pass with the new display name/cache key.

- [ ] **Step 7: Commit the product identity**

```bash
git add package.json package-lock.json index.html scripts/release-contract.test.mjs src/lib/appUpdate.ts src/lib/appUpdate.test.ts src/lib/i18n.ts src-tauri/Cargo.toml src-tauri/Cargo.lock src-tauri/tauri.conf.json src-tauri/capabilities/default.json src-tauri/src/lib.rs macos-signing/project.yml macos-signing/SigningHost/Info.plist macos-signing/SigningHost/SigningHostApp.swift src-macos-widget/Info.plist src-macos-widget/Core/QuotaFormatter.swift src-macos-widget/Data/QuotaSnapshotStore.swift src-macos-widget-tests/QuotaFormatterTests.swift src-macos-widget-tests/QuotaSnapshotStoreTests.swift
git commit -m "feat: establish Quota Float Mood identity"
```

---

### Task 2: Publish the Action-First README, Attribution, and Support Image

**Files:**
- Modify: `README.md`
- Create: `NOTICE.md`
- Create: `docs/images/wechat-support.jpg`
- Modify: `PRIVACY.md`
- Modify: `SECURITY.md`
- Modify: `CONTRIBUTING.md`
- Modify: `scripts/release-contract.test.mjs`

**Interfaces:**
- Consumes: Product/repository identity from Task 1 and the user-supplied JPEG at `/var/folders/lg/vd08t8td7y74p1gm5v0p_crc0000gn/T/codex-clipboard-1e688ee9-a14e-477c-9ad4-602d80d8a010.jpg`.
- Produces: Logged-out landing page, explicit upstream credit, and optional support section.

- [ ] **Step 1: Strengthen the contract test for attribution and voluntary payment**

Add these assertions to the README test:

```js
assert.match(readme, /完全免费/);
assert.match(readme, /是否支持完全自愿/);
assert.match(readme, /Mark-0513/);
assert.match(read("NOTICE.md"), /Based on Quota Float/);
assert.match(read("NOTICE.md"), /MIT License/);
```

- [ ] **Step 2: Run the contract test and verify RED**

Run `node --test scripts/release-contract.test.mjs`.

Expected: FAIL because `NOTICE.md`, the support image, and required concise copy do not exist.

- [ ] **Step 3: Add the public support asset and action-first documentation**

Copy the supplied image byte-for-byte to `docs/images/wechat-support.jpg`. Rewrite the README in this order:

```markdown
# Quota Float Mood

免费、开源的 macOS Codex 额度小组件，提供 6 套带情绪表达的主题，每套支持小号和中号。

## 免费下载

[👉 下载最新版](https://github.com/Mark-0513/quota-float-mood/releases/latest)

普通用户只需要下载：`Quota-Float-Mood-v0.2.0-macOS-Universal.dmg`

支持 Intel 与 Apple 芯片 Mac，需要 macOS 14 或更高版本。需要本机已安装并登录 Codex Desktop。

## 安装

1. 下载并打开 DMG。
2. 把 Quota Float Mood 拖进“应用程序”。
3. 启动应用，然后在 macOS 小组件库中搜索 Quota Float Mood。

## 喜欢这个项目？

如果它对你有帮助，请点击仓库右上角的 **Star ⭐**。你的 Star 会让更多人发现这个项目，也会鼓励我们继续更新新皮肤。

## 自愿支持

软件完全免费、源码开放。你可以自愿支持增强版维护者 Mark；是否支持完全自愿，不影响任何功能。

![微信支持 Mark](docs/images/wechat-support.jpg)
```

After these sections, retain concise privacy, accuracy, development, upstream, and license sections. Add `NOTICE.md` that names the upstream URL, MIT license, upstream contributors, and Mark's WidgetKit/theme work. Update `PRIVACY.md`, `SECURITY.md`, and `CONTRIBUTING.md` only where the product/repository name or report URL is user-visible.

- [ ] **Step 4: Run the contract test and verify GREEN**

Run `node --test scripts/release-contract.test.mjs`.

Expected: all contract tests pass.

- [ ] **Step 5: Commit documentation and support asset**

```bash
git add README.md NOTICE.md PRIVACY.md SECURITY.md CONTRIBUTING.md docs/images/wechat-support.jpg scripts/release-contract.test.mjs
git commit -m "docs: add free download and optional support"
```

---

### Task 3: Build One Reproducible Universal macOS DMG

**Files:**
- Create: `scripts/build-macos-distribution.sh`
- Modify: `scripts/embed-macos-widget.sh`
- Modify: `scripts/macos-smoke-capture.sh`
- Modify: `.gitignore`
- Modify: `scripts/release-contract.test.mjs`

**Interfaces:**
- Consumes: Tauri universal `.app`, XcodeGen WidgetKit host/extension, `SIGN_IDENTITY` environment variable.
- Produces: `release/Quota-Float-Mood-v0.2.0-macOS-Universal.dmg` and matching `.sha256`.

- [ ] **Step 1: Add packaging requirements to the failing contract test**

Add:

```js
test("builds the documented universal DMG", () => {
  const script = read("scripts/build-macos-distribution.sh");
  assert.match(script, /Quota-Float-Mood-v\$\{VERSION\}-macOS-Universal\.dmg/);
  assert.match(script, /arm64/);
  assert.match(script, /x86_64/);
  assert.match(script, /codesign --verify --deep --strict/);
  assert.match(script, /shasum -a 256/);
});
```

- [ ] **Step 2: Run the contract test and verify RED**

Run `node --test scripts/release-contract.test.mjs`.

Expected: FAIL because the distribution script is missing.

- [ ] **Step 3: Implement deterministic build, embed, signing, and DMG creation**

Create an executable zsh script with these fixed stages:

```text
1. Verify macOS, node/npm, rustup, xcodegen, xcodebuild, hdiutil, codesign, and lipo.
2. Remove and recreate only repository-local `release/build` staging paths.
3. Install both Rust macOS targets.
4. Run npm tests, Rust tests, and WidgetKit tests.
5. Build the Tauri app with `npm run tauri -- build --target universal-apple-darwin --bundles app`.
6. Build the WidgetKit host with arm64 and x86_64 using XcodeGen/Xcode.
7. Copy `Quota Float Mood Widget.appex` into the Tauri app's `Contents/PlugIns`.
8. Sign the extension with its entitlements, then the host. Use `SIGN_IDENTITY=-` for an explicitly unsigned/ad-hoc beta; use timestamped Hardened Runtime when a Developer ID identity is supplied.
9. Verify deep/strict signatures and lipo slices for both host and extension.
10. Create a staging folder containing the app and an Applications symlink.
11. Create `Quota-Float-Mood-v0.2.0-macOS-Universal.dmg` with hdiutil.
12. Write the SHA-256 line to the matching `.sha256` file.
```

The script must refuse to label a build notarized unless `SIGN_IDENTITY` begins with `Developer ID Application:` and `NOTARIZE=1`; notarization must use `xcrun notarytool submit --wait`, followed by `xcrun stapler staple` and `spctl --assess --type open --context context:primary-signature`.

Update `embed-macos-widget.sh` and `macos-smoke-capture.sh` to use Quota Float Mood paths. Ignore `/release/` and generated Xcode/DerivedData paths without ignoring the distribution script or documentation.

- [ ] **Step 4: Run source contract and shell syntax checks**

```bash
node --test scripts/release-contract.test.mjs
zsh -n scripts/build-macos-distribution.sh
zsh -n scripts/embed-macos-widget.sh
bash -n scripts/macos-smoke-capture.sh
```

Expected: all commands exit 0.

- [ ] **Step 5: Build the unsigned/ad-hoc beta artifact locally**

```bash
SIGN_IDENTITY=- NOTARIZE=0 scripts/build-macos-distribution.sh
```

Expected: the DMG and checksum exist under `release/`, signatures verify structurally, and both binaries report `arm64 x86_64`. The script labels the artifact unsigned/ad-hoc and does not claim Gatekeeper acceptance.

- [ ] **Step 6: Commit packaging support**

```bash
git add .gitignore scripts/build-macos-distribution.sh scripts/embed-macos-widget.sh scripts/macos-smoke-capture.sh scripts/release-contract.test.mjs
git commit -m "build: package universal mood widget dmg"
```

---

### Task 4: Make CI and Releases Match the Public Download Contract

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/release.yml`
- Modify: `docs/GITHUB-RELEASE-CHECKLIST.md`
- Modify: `docs/RELEASE_TEMPLATE.md`
- Modify: `scripts/release-contract.test.mjs`

**Interfaces:**
- Consumes: `npm run test:release-contract` and `scripts/build-macos-distribution.sh`.
- Produces: CI gates and a tag-triggered prerelease with one DMG and checksum.

- [ ] **Step 1: Add workflow contract assertions and verify RED**

Add assertions that the release workflow:

```js
const releaseWorkflow = read(".github/workflows/release.yml");
assert.match(releaseWorkflow, /scripts\/build-macos-distribution\.sh/);
assert.match(releaseWorkflow, /Quota-Float-Mood-v0\.2\.0-macOS-Universal\.dmg/);
assert.match(releaseWorkflow, /prerelease: true/);
```

Run `node --test scripts/release-contract.test.mjs` and confirm it fails against the upstream Tauri release workflow.

- [ ] **Step 2: Replace the release workflow with a macOS-only beta publisher**

The `v*` workflow must:

```text
- check out the tag
- install Node 22, Rust stable, arm64/x86_64 Rust targets, and XcodeGen
- run `npm ci`
- run `npm run test:release-contract`
- run `SIGN_IDENTITY=- NOTARIZE=0 scripts/build-macos-distribution.sh`
- publish the DMG and `.sha256` as a GitHub prerelease
- state plainly that v0.2.0 is unsigned/ad-hoc and include the Gatekeeper approval steps
```

Update CI so Ubuntu runs frontend/Rust/release-contract tests and macOS runs WidgetKit tests plus the clean universal package smoke build. Update the release checklist/template to use the exact repository, asset name, macOS floor, upstream credit, unsigned-beta warning, and later Developer ID upgrade path.

- [ ] **Step 3: Verify workflow syntax and contract GREEN**

Run:

```bash
node --test scripts/release-contract.test.mjs
git diff --check
```

Expected: all contract tests pass and no whitespace errors are reported.

- [ ] **Step 4: Commit automation**

```bash
git add .github/workflows/ci.yml .github/workflows/release.yml docs/GITHUB-RELEASE-CHECKLIST.md docs/RELEASE_TEMPLATE.md scripts/release-contract.test.mjs
git commit -m "ci: publish Quota Float Mood beta releases"
```

---

### Task 5: Run the Full Local Release Gate

**Files:**
- Modify only if verification reveals a scoped defect in files from Tasks 1-4.

**Interfaces:**
- Consumes: all source, tests, and release scripts.
- Produces: verified commit suitable for public push and exact local DMG hash.

- [ ] **Step 1: Run all automated tests**

```bash
npm run test:release-contract
npm test
cargo test --manifest-path src-tauri/Cargo.toml
xcodegen generate --spec macos-signing/project.yml --project macos-signing
xcodebuild -project macos-signing/QuotaFloatSigning.xcodeproj -scheme QuotaFloatMoodSigningHost -configuration Release -derivedDataPath macos-signing/DerivedDataReleaseFinal test CODE_SIGNING_ALLOWED=NO
```

Expected: every suite passes with no test failures.

- [ ] **Step 2: Build and inspect the final local artifact**

```bash
SIGN_IDENTITY=- NOTARIZE=0 scripts/build-macos-distribution.sh
shasum -a 256 -c release/Quota-Float-Mood-v0.2.0-macOS-Universal.dmg.sha256
```

Expected: checksum reports `OK`; host and widget contain arm64/x86_64; deep/strict codesign succeeds; the build log explicitly says unsigned/ad-hoc beta.

- [ ] **Step 3: Scan for secrets and stale operational links**

```bash
rg -n "BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|ghp_|github_pat_|sk-[A-Za-z0-9]|TAURI_SIGNING_PRIVATE_KEY_PASSWORD" --glob '!package-lock.json' --glob '!docs/superpowers/**' .
rg -n "change-42-yhmm/quota-float/releases" src src-tauri macos-signing scripts .github README.md
```

Expected: no secrets and no operational upstream release URLs. Upstream attribution links in README/NOTICE are allowed.

- [ ] **Step 4: Review the final scope**

```bash
git status --short --branch
git diff --check
git log --oneline --decorate -8
```

Expected: only the pre-existing generated `src-tauri/gen/schemas/macOS-schema.json` remains untracked; all release changes are committed intentionally.

---

### Task 6: Create and Publish the GitHub Fork

**Files:**
- No source file changes expected.
- External state: `Mark-0513/quota-float-mood` repository and Git remotes.

**Interfaces:**
- Consumes: verified local branch and authenticated `gh` session for `Mark-0513`.
- Produces: public fork with enhanced code on its default `main` branch.

- [ ] **Step 1: Verify authentication, permissions, and history**

```bash
gh --version
gh auth status
git status --short --branch
git fetch --unshallow origin
git merge-base --is-ancestor origin/main HEAD
```

Expected: `gh` is authenticated as `Mark-0513`, the only unrelated working-tree item is the generated macOS schema, and upstream `main` is an ancestor of the release branch.

- [ ] **Step 2: Create the public fork and rename it**

```bash
gh repo fork change-42-yhmm/quota-float --clone=false
gh repo rename quota-float-mood --repo Mark-0513/quota-float --yes
```

Expected: `gh repo view Mark-0513/quota-float-mood --json isFork,parent,visibility` reports a public fork whose parent is `change-42-yhmm/quota-float`.

- [ ] **Step 3: Configure safe upstream/origin remotes**

```bash
git remote rename origin upstream
git remote add origin https://github.com/Mark-0513/quota-float-mood.git
git remote -v
```

Expected: `origin` points to Mark's fork and `upstream` points to the original project.

- [ ] **Step 4: Push the verified branch as the fork's main branch**

```bash
git push -u origin HEAD:main
gh repo edit Mark-0513/quota-float-mood --description "Free open-source macOS Codex quota widgets with six emotional themes" --homepage "https://github.com/Mark-0513/quota-float-mood/releases/latest" --add-topic codex --add-topic macos --add-topic widgetkit --add-topic tauri --add-topic open-source
```

Expected: the push is a fast-forward, `main` contains the release commits, and the repository metadata is public and accurate.

---

### Task 7: Publish and Verify v0.2.0 Download

**Files:**
- No source changes expected unless GitHub Actions reveals a release-only defect, which must be fixed in a separate focused commit before retagging.

**Interfaces:**
- Consumes: public fork `main`, final local verification, and release workflow.
- Produces: public `v0.2.0` prerelease URL and downloadable DMG/checksum.

- [ ] **Step 1: Create and push the release tag**

```bash
git tag -a v0.2.0 -m "Quota Float Mood v0.2.0"
git push origin v0.2.0
```

Expected: the Release workflow starts for tag `v0.2.0`.

- [ ] **Step 2: Wait for GitHub Actions and inspect every result**

```bash
gh run list --repo Mark-0513/quota-float-mood --workflow Release --limit 5
gh run watch --repo Mark-0513/quota-float-mood --exit-status
```

Expected: Release workflow completes successfully. If it fails, inspect `gh run view --log-failed`, fix the root cause, delete only the failed tag/release after resolving exact targets, create `v0.2.1`, and rerun; do not overwrite a working public artifact.

- [ ] **Step 3: Verify the public release and logged-out links**

```bash
gh release view v0.2.0 --repo Mark-0513/quota-float-mood --json url,isPrerelease,assets
gh release download v0.2.0 --repo Mark-0513/quota-float-mood --pattern 'Quota-Float-Mood-v0.2.0-macOS-Universal*' --dir release/download-check
shasum -a 256 -c release/download-check/Quota-Float-Mood-v0.2.0-macOS-Universal.dmg.sha256
```

Expected: the release is public and marked prerelease; the exact DMG and checksum are present; downloaded checksum is `OK`.

- [ ] **Step 4: Mount the downloaded DMG and verify its exact app**

Mount read-only, then verify:

```text
- product name is Quota Float Mood
- main bundle ID is com.mark0513.quotafloatmood
- widget bundle ID is com.mark0513.quotafloatmood.widget
- host and extension are arm64/x86_64
- deep/strict structural signatures pass
- README and Release notes label it unsigned/ad-hoc beta
```

Install the downloaded app, perform the documented Gatekeeper approval path, open it, confirm live quota retrieval, and confirm all 12 Widget Gallery entries appear.

- [ ] **Step 5: Hand off the public links**

Return these links to the user:

```text
Repository: https://github.com/Mark-0513/quota-float-mood
Latest download: https://github.com/Mark-0513/quota-float-mood/releases/latest
Release: https://github.com/Mark-0513/quota-float-mood/releases/tag/v0.2.0
```

State whether the artifact is notarized or unsigned/ad-hoc, the exact file users should download, the verified SHA-256 value, and that payment remains optional.
