# Quota Float Multi-Theme macOS Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add six independently selectable, emotionally expressive Quota Float widgets to the macOS widget gallery, with small and medium layouts, cached fallback data, automated logic tests, and a verified local installation.

**Architecture:** Keep API decoding, percentage normalization, mood classification, caching, timeline loading, formatting, and accessibility shared. Expose six `StaticConfiguration` values from one `WidgetBundle`, while each theme owns separate small and medium SwiftUI compositions so visual identity is not reduced to color tokens.

**Tech Stack:** Swift 5, SwiftUI, WidgetKit, Foundation `URLSession`, `UserDefaults`, XCTest, XcodeGen, Xcode 26, existing Rust/Tauri host application.

## Global Constraints

- Minimum supported system remains macOS 14.
- Support only `.systemSmall` and `.systemMedium` in this phase.
- Expose six independent configurations under the Quota Float gallery category.
- Do not add third-party Swift packages or change the React/Tauri main-window UI.
- Keep the existing loopback endpoint `http://127.0.0.1:47842/snapshot`; never persist tokens or credentials.
- Treat missing quota data as `unavailable`, never as `0%`.
- Mood thresholds are exact: `70...100` abundant, `30..<70` steady, `10..<30` tense, `0..<10` critical.
- Preserve the previous installed app until the replacement passes launch, signature, gallery, and live-data checks.
- Design source of truth: `docs/superpowers/specs/2026-07-18-quota-float-widget-themes-design.md`.

## File Structure

- Modify `src-macos-widget/QuotaFloatWidget.swift`: keep only the `@main WidgetBundle` and six widget configuration definitions.
- Create `src-macos-widget/Core/QuotaModels.swift`: API models, cached envelope, display-window and display-model types.
- Create `src-macos-widget/Core/QuotaMood.swift`: percentage clamping and mood classification.
- Create `src-macos-widget/Core/QuotaFormatter.swift`: percentage, reset-time, and cache-age formatting.
- Create `src-macos-widget/Core/QuotaThemeCopy.swift`: six theme identifiers and exact mood/empty-state copy.
- Create `src-macos-widget/Data/QuotaSnapshotStore.swift`: network request, successful-response cache, and cache fallback.
- Create `src-macos-widget/Data/QuotaTimelineProvider.swift`: WidgetKit entry, preview data, snapshot, and timeline scheduling.
- Create `src-macos-widget/Views/Shared/QuotaSharedViews.swift`: accessibility text, progress-width helper, and small shared badges.
- Create six files under `src-macos-widget/Views/Themes/`: independent small/medium SwiftUI views.
- Create `src-macos-widget-tests/QuotaMoodTests.swift`, `QuotaFormatterTests.swift`, `QuotaThemeCopyTests.swift`, and `QuotaSnapshotStoreTests.swift`.
- Modify `macos-signing/project.yml`: compile the new directory tree and add a standalone macOS logic-test target.
- Modify `scripts/embed-macos-widget.sh`: remove the experimental restricted host entitlements and embed the final Xcode-built extension safely.

---

### Task 1: Mood Classification and Display Models

**Files:**
- Create: `src-macos-widget/Core/QuotaModels.swift`
- Create: `src-macos-widget/Core/QuotaMood.swift`
- Create: `src-macos-widget-tests/QuotaMoodTests.swift`
- Modify: `macos-signing/project.yml`

**Interfaces:**
- Produces: `QuotaMood.classify(_:) -> QuotaMood`
- Produces: `QuotaMood.clampedPercent(_:) -> Double?`
- Produces: `QuotaDisplayWindow.init(window:)`
- Produces: `QuotaDisplayModel.init(snapshot:source:)`
- Consumes: existing JSON field names from the Rust `ProviderSnapshot` response.

- [ ] **Step 1: Add the failing boundary tests**

Create `src-macos-widget-tests/QuotaMoodTests.swift`:

```swift
import XCTest

final class QuotaMoodTests: XCTestCase {
    func testExactMoodBoundaries() {
        XCTAssertEqual(QuotaMood.classify(100), .abundant)
        XCTAssertEqual(QuotaMood.classify(70), .abundant)
        XCTAssertEqual(QuotaMood.classify(69), .steady)
        XCTAssertEqual(QuotaMood.classify(30), .steady)
        XCTAssertEqual(QuotaMood.classify(29), .tense)
        XCTAssertEqual(QuotaMood.classify(10), .tense)
        XCTAssertEqual(QuotaMood.classify(9), .critical)
        XCTAssertEqual(QuotaMood.classify(0), .critical)
        XCTAssertEqual(QuotaMood.classify(nil), .unavailable)
    }

    func testPercentIsClampedBeforeClassification() {
        XCTAssertEqual(QuotaMood.clampedPercent(-20), 0)
        XCTAssertEqual(QuotaMood.clampedPercent(140), 100)
        XCTAssertEqual(QuotaMood.classify(-20), .critical)
        XCTAssertEqual(QuotaMood.classify(140), .abundant)
    }
}
```

- [ ] **Step 2: Add the test target and verify red tests**

Add a `QuotaFloatWidgetTests` `bundle.unit-test` target to `macos-signing/project.yml`. Include `../src-macos-widget-tests`, `../src-macos-widget/Core/QuotaModels.swift`, and `../src-macos-widget/Core/QuotaMood.swift` as sources. Add it to the scheme's `test.targets` list.

Run:

```bash
cd macos-signing
xcodegen generate --spec project.yml
xcodebuild -project QuotaFloatSigning.xcodeproj -scheme QuotaFloatSigningHost -configuration Debug -derivedDataPath DerivedDataTests test
```

Expected: FAIL because `QuotaMood`, `QuotaDisplayWindow`, and the new model types do not exist.

- [ ] **Step 3: Implement raw and display models**

Create `src-macos-widget/Core/QuotaModels.swift` with these concrete types:

```swift
import Foundation

struct UsageWindow: Codable, Equatable {
    let remainingPercent: Double
    let resetsAt: String?
    let windowSeconds: UInt64
}

struct ProviderSnapshot: Codable, Equatable {
    let provider: String
    let displayName: String
    let plan: String?
    let shortWindow: UsageWindow?
    let weeklyWindow: UsageWindow?
    let resetCredits: UInt64?
    let resetCreditExpiresAt: [String]
    let updatedAt: String
    let status: String
    let message: String?

    static func unavailable(message: String?) -> ProviderSnapshot {
        ProviderSnapshot(
            provider: "codex",
            displayName: "CODEX",
            plan: nil,
            shortWindow: nil,
            weeklyWindow: nil,
            resetCredits: nil,
            resetCreditExpiresAt: [],
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            status: "unavailable",
            message: message
        )
    }
}

struct CachedSnapshot: Codable, Equatable {
    let snapshot: ProviderSnapshot
    let cachedAt: Date
}

enum QuotaSource: Equatable {
    case live
    case cached(savedAt: Date, isOlderThanOneDay: Bool)
    case unavailable(message: String?)
}

struct QuotaDisplayWindow: Equatable {
    let remainingPercent: Double?
    let mood: QuotaMood
    let resetsAt: String?

    init(window: UsageWindow?) {
        remainingPercent = QuotaMood.clampedPercent(window?.remainingPercent)
        mood = QuotaMood.classify(window?.remainingPercent)
        resetsAt = window?.resetsAt
    }
}

struct QuotaDisplayModel: Equatable {
    let plan: String?
    let short: QuotaDisplayWindow
    let weekly: QuotaDisplayWindow
    let source: QuotaSource

    init(snapshot: ProviderSnapshot, source: QuotaSource) {
        plan = snapshot.plan
        short = QuotaDisplayWindow(window: snapshot.shortWindow)
        weekly = QuotaDisplayWindow(window: snapshot.weeklyWindow)
        self.source = source
    }
}
```

- [ ] **Step 4: Implement exact mood behavior**

Create `src-macos-widget/Core/QuotaMood.swift`:

```swift
import Foundation

enum QuotaMood: String, Equatable, CaseIterable {
    case abundant
    case steady
    case tense
    case critical
    case unavailable

    static func clampedPercent(_ rawValue: Double?) -> Double? {
        guard let rawValue, rawValue.isFinite else { return nil }
        return min(100, max(0, rawValue))
    }

    static func classify(_ rawValue: Double?) -> QuotaMood {
        guard let value = clampedPercent(rawValue) else { return .unavailable }
        if value >= 70 { return .abundant }
        if value >= 30 { return .steady }
        if value >= 10 { return .tense }
        return .critical
    }
}
```

- [ ] **Step 5: Run the logic tests**

Run the same `xcodebuild ... test` command.

Expected: `QuotaMoodTests` PASS with 2 tests and 13 assertions.

- [ ] **Step 6: Commit the independently tested core**

```bash
git add macos-signing/project.yml src-macos-widget/Core src-macos-widget-tests/QuotaMoodTests.swift
git commit -m "feat(widget): add quota mood classification"
```

---

### Task 2: Formatting and Theme-Specific Emotional Copy

**Files:**
- Create: `src-macos-widget/Core/QuotaFormatter.swift`
- Create: `src-macos-widget/Core/QuotaThemeCopy.swift`
- Create: `src-macos-widget-tests/QuotaFormatterTests.swift`
- Create: `src-macos-widget-tests/QuotaThemeCopyTests.swift`
- Modify: `macos-signing/project.yml`

**Interfaces:**
- Consumes: `QuotaMood`, `QuotaDisplayWindow`, and `QuotaSource` from Task 1.
- Produces: `QuotaFormatter.percent(_:)`, `resetText(_:)`, and `sourceText(_:)`.
- Produces: `QuotaThemeID.copy(for:) -> ThemeMoodCopy` and `emptyCopy`.

- [ ] **Step 1: Write failing formatter and copy tests**

Tests must assert these exact outcomes:

```swift
XCTAssertEqual(QuotaFormatter.percent(86.4), "86%")
XCTAssertEqual(QuotaFormatter.percent(nil), "--")
XCTAssertEqual(QuotaThemeID.pixel.copy(for: .abundant).headline, "满血嚣张")
XCTAssertEqual(QuotaThemeID.terminal.copy(for: .critical).headline, "CORE CRITICAL")
XCTAssertEqual(QuotaThemeID.vault.copy(for: .tense).headline, "余额告急")
XCTAssertEqual(QuotaThemeID.blackGold.copy(for: .critical).headline, "尊贵值见底")
XCTAssertEqual(QuotaThemeID.sticker.copy(for: .tense).headline, "开始慌了")
XCTAssertEqual(QuotaThemeID.proudBot.copy(for: .abundant).headline, "我能打十个")
XCTAssertEqual(QuotaThemeID.proudBot.emptyCopy, "雷达未回传")
```

Run the Xcode test command from Task 1.

Expected: FAIL because formatter and theme-copy types do not exist.

- [ ] **Step 2: Implement formatting without view dependencies**

`QuotaFormatter` must use a `zh_CN` date formatter, parse ISO-8601 with and without fractional seconds, render `M月d日 HH:mm 重置`, return `重置时间未知` for invalid values, and mark cache ages over 24 hours as `数据较旧`.

Use this public surface:

```swift
enum QuotaFormatter {
    static func percent(_ value: Double?) -> String
    static func resetText(_ rawDate: String?) -> String
    static func sourceText(_ source: QuotaSource, now: Date = Date()) -> String?
}
```

- [ ] **Step 3: Implement the six complete copy tables**

Create `QuotaThemeID` with cases `pixel`, `terminal`, `vault`, `blackGold`, `sticker`, and `proudBot`. `ThemeMoodCopy` contains `headline` and `detail`. Implement all 30 combinations from the approved spec: five states for each of six themes. Do not derive one theme's copy from another theme.

- [ ] **Step 4: Run all tests and commit**

Expected: formatter and copy tests PASS; existing mood tests remain green.

```bash
git add macos-signing/project.yml src-macos-widget/Core src-macos-widget-tests
git commit -m "feat(widget): add emotional theme copy"
```

---

### Task 3: Live Snapshot Loading and Cached Fallback

**Files:**
- Create: `src-macos-widget/Data/QuotaSnapshotStore.swift`
- Create: `src-macos-widget-tests/QuotaSnapshotStoreTests.swift`
- Modify: `macos-signing/project.yml`

**Interfaces:**
- Consumes: `ProviderSnapshot`, `CachedSnapshot`, and `QuotaSource`.
- Produces: `QuotaSnapshotStore.load(now:) async -> QuotaLoadResult`.
- Produces: `QuotaLoadResult(snapshot:source:)`.

Define the result type exactly as:

```swift
struct QuotaLoadResult: Equatable {
    let snapshot: ProviderSnapshot
    let source: QuotaSource
}
```

- [ ] **Step 1: Write failing cache and network-fallback tests**

Use an isolated `UserDefaults(suiteName:)` and an injected `URLSession` backed by a test `URLProtocol`. Cover four cases:

1. HTTP 200 valid array returns the first snapshot with `.live` and writes cache.
2. Timeout with a 2-hour-old cache returns `.cached(isOlderThanOneDay: false)`.
3. HTTP 500 with a 25-hour-old cache returns `.cached(isOlderThanOneDay: true)`.
4. Invalid JSON with no cache returns `.unavailable` and the static unavailable snapshot.

Run the Xcode test command.

Expected: FAIL because `QuotaSnapshotStore` does not exist.

- [ ] **Step 2: Implement cache storage**

Use one key, `app.quotafloat.widget.last-successful-snapshot`, and `JSONEncoder`/`JSONDecoder`. Inject `UserDefaults` through the initializer so tests never modify the installed extension's real cache.

- [ ] **Step 3: Implement network-first loading**

The initializer must accept:

```swift
init(
    session: URLSession = .shared,
    defaults: UserDefaults = .standard,
    endpoint: URL = URL(string: "http://127.0.0.1:47842/snapshot")!
)
```

Set request cache policy to `.reloadIgnoringLocalAndRemoteCacheData` and timeout to 4 seconds. Accept only HTTP 200 and a non-empty decoded `[ProviderSnapshot]`. On any failure, read cache; if cache is absent, return a `ProviderSnapshot.unavailable(message:)` factory value.

- [ ] **Step 4: Verify data tests and commit**

Expected: all four store tests PASS and no real network request occurs in the test run.

```bash
git add macos-signing/project.yml src-macos-widget/Data src-macos-widget-tests/QuotaSnapshotStoreTests.swift
git commit -m "feat(widget): cache the latest quota snapshot"
```

---

### Task 4: Timeline Provider and Six Gallery Configurations

**Files:**
- Create: `src-macos-widget/Data/QuotaTimelineProvider.swift`
- Replace: `src-macos-widget/QuotaFloatWidget.swift`
- Modify: `macos-signing/project.yml`

**Interfaces:**
- Consumes: `QuotaSnapshotStore.load(now:)` and `QuotaDisplayModel`.
- Produces: `QuotaEntry(date:model:)` and `QuotaTimelineProvider`.
- Produces: six stable widget kinds consumed by macOS WidgetKit.

- [ ] **Step 1: Create the shared timeline provider**

`QuotaTimelineProvider` must:

- return an 82%/64% preview model without network access;
- call `QuotaSnapshotStore.load()` for snapshots and timelines;
- schedule `.after(nextRefresh)` at 15 minutes;
- always invoke completion, including decoding and network failures.

- [ ] **Step 2: Replace the single widget entry point with a bundle**

`QuotaFloatWidget.swift` must contain:

```swift
import SwiftUI
import WidgetKit

@main
struct QuotaFloatWidgetBundle: WidgetBundle {
    var body: some Widget {
        PixelQuotaWidget()
        TerminalQuotaWidget()
        VaultQuotaWidget()
        BlackGoldQuotaWidget()
        StickerQuotaWidget()
        ProudBotQuotaWidget()
    }
}
```

Each widget must use `StaticConfiguration`, `QuotaTimelineProvider`, a unique kind from the design spec, `.supportedFamilies([.systemSmall, .systemMedium])`, `.contentMarginsDisabled()`, and its own Chinese display name and description.

- [ ] **Step 3: Add temporary compile-safe theme roots**

Create each theme file with a minimal `Text` view accepting `QuotaDisplayModel` so the bundle compiles before visual implementation. These temporary roots are replaced in Tasks 5–7 and must not survive final verification.

- [ ] **Step 4: Build the extension**

```bash
cd macos-signing
xcodegen generate --spec project.yml
xcodebuild -quiet -project QuotaFloatSigning.xcodeproj -scheme QuotaFloatSigningHost -configuration Release -derivedDataPath DerivedDataUnsigned CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Expected: BUILD SUCCEEDED and the generated app contains one `.appex` whose WidgetBundle exposes six configurations.

- [ ] **Step 5: Commit the registry and provider**

```bash
git add src-macos-widget macos-signing/project.yml
git commit -m "feat(widget): register six quota widgets"
```

---

### Task 5: Shared Visual Primitives, Pixel Quest, and Cyber Terminal

**Files:**
- Create: `src-macos-widget/Views/Shared/QuotaSharedViews.swift`
- Create: `src-macos-widget/Views/Themes/PixelQuotaView.swift`
- Create: `src-macos-widget/Views/Themes/TerminalQuotaView.swift`

**Interfaces:**
- Consumes: `QuotaDisplayModel`, `QuotaThemeID`, and `QuotaFormatter`.
- Produces: `PixelQuotaView(model:)` and `TerminalQuotaView(model:)`.
- Produces shared accessibility and geometry helpers only; theme layouts remain independent.

- [ ] **Step 1: Implement shared non-styling helpers**

Add `QuotaAccessibility.summary(theme:model:)`, `QuotaBarWidth(percent:availableWidth:)`, `PlanBadge`, and `CacheStatusLabel`. Do not add a shared complete widget layout.

- [ ] **Step 2: Implement both Pixel Quest sizes**

Small: 5-pixel border, game title, primary percent, segmented life bar, heart/level status, and weekly summary. Medium: two independent stat panels for `5H ENERGY` and `WEEKLY XP`, plus mood headline. Use Monaco as the built-in pixel-like fallback and no bundled custom font.

Mood changes must affect at least the headline, bar color, heart count, and warning symbol. Missing 5-hour data shows `WAITING SERVER` while weekly data remains live.

- [ ] **Step 3: Implement both Cyber Terminal sizes**

Use a black-green terminal surface, subtle scan-line overlay, system identifiers, equal-width numbers, and mood-specific core status. Critical state adds red status text and a broken-line bar; unavailable state displays `NO SIGNAL` without showing `0%`.

- [ ] **Step 4: Build and inspect previews**

Build Release. Open Xcode previews for both families using abundant, tense, critical, and unavailable fixtures. Expected: no clipped values or duplicate shared-layout appearance.

- [ ] **Step 5: Commit the first two themes**

```bash
git add src-macos-widget/Views
git commit -m "feat(widget): add pixel and terminal themes"
```

---

### Task 6: Fortune Vault and Black Gold Club

**Files:**
- Create: `src-macos-widget/Views/Themes/VaultQuotaView.swift`
- Create: `src-macos-widget/Views/Themes/BlackGoldQuotaView.swift`

**Interfaces:**
- Consumes the same immutable `QuotaDisplayModel` used by Task 5.
- Produces `VaultQuotaView(model:)` and `BlackGoldQuotaView(model:)`.

- [ ] **Step 1: Implement Fortune Vault small and medium layouts**

Use gold-on-black assets drawn entirely with SwiftUI shapes. Map remaining percentage to 0–5 visible coin-stack segments. Use the exact mood copy `富得流油 / 精打细算 / 余额告急 / 破产边缘`; missing data says `等待入账`.

- [ ] **Step 2: Implement Black Gold Club small and medium layouts**

Use restrained brass rules, membership numbering, serif numerals, and a distinct card composition. Do not reuse the Vault coin stack. Map mood to membership language and let critical status visibly interrupt the otherwise formal layout.

- [ ] **Step 3: Build and visually compare the two gold themes**

Expected: Vault reads as wealth/asset abundance; Black Gold reads as premium membership/status. Their gallery thumbnails must be distinguishable at a glance.

- [ ] **Step 4: Commit the two themes**

```bash
git add src-macos-widget/Views/Themes/VaultQuotaView.swift src-macos-widget/Views/Themes/BlackGoldQuotaView.swift
git commit -m "feat(widget): add vault and black gold themes"
```

---

### Task 7: Street Sticker and Proud Robot

**Files:**
- Create: `src-macos-widget/Views/Themes/StickerQuotaView.swift`
- Create: `src-macos-widget/Views/Themes/ProudBotQuotaView.swift`

**Interfaces:**
- Consumes the shared display model and exact theme-copy table.
- Produces `StickerQuotaView(model:)` and `ProudBotQuotaView(model:)`.

- [ ] **Step 1: Implement Street Sticker small and medium layouts**

Use silver-gray background, layered SwiftUI sticker shapes, controlled rotation, fluorescent accent colors, and direct Chinese mood copy. Maintain a clean numeric hierarchy so the theme feels collectible rather than chaotic.

- [ ] **Step 2: Implement Proud Robot small and medium layouts**

Build the robot face from SwiftUI shapes. Abundant uses raised eyes plus a crown; steady uses a neutral confident face; tense uses one sweat mark and a stubborn mouth; critical uses dim eyes and a request-for-charge symbol. Unavailable uses a radar icon and `雷达未回传`.

- [ ] **Step 3: Run the complete test and build suite**

Run the Xcode test command, then the unsigned Release build command.

Expected: all logic tests PASS; Release build succeeds; no temporary `Text` theme roots remain.

- [ ] **Step 4: Commit the final themes**

```bash
git add src-macos-widget/Views/Themes src-macos-widget/QuotaFloatWidget.swift
git commit -m "feat(widget): add sticker and proud robot themes"
```

---

### Task 8: Accessibility, Copy, and Twelve-Layout Visual QA

**Files:**
- Modify: all six files under `src-macos-widget/Views/Themes/`
- Modify: `src-macos-widget/Views/Shared/QuotaSharedViews.swift`
- Test: all files under `src-macos-widget-tests/`

**Interfaces:**
- Consumes final theme views.
- Produces verified VoiceOver strings and visual acceptance evidence for 12 layouts.

- [ ] **Step 1: Add accessibility assertions**

Test that summaries include plan, window label, exact percent or unavailable wording, mood headline, reset time when present, and cache status when applicable.

- [ ] **Step 2: Verify five fixture states per theme**

Use fixed preview models for 86%, 47%, 18%, 6%, and unavailable. Inspect small and medium at each state. Record any truncation or low-contrast issue before continuing.

- [ ] **Step 3: Check system adaptations**

Inspect light appearance, dark appearance, and Reduce Transparency. Ensure critical states use both copy/icon and color, and VoiceOver does not read decorative symbols.

- [ ] **Step 4: Run tests and commit polish**

```bash
git add src-macos-widget src-macos-widget-tests
git commit -m "test(widget): verify theme states and accessibility"
```

---

### Task 9: Safe Build, Signing, Installation, and macOS Gallery Verification

**Files:**
- Modify: `scripts/embed-macos-widget.sh`
- Use: `src-macos-widget/QuotaFloatWidget.entitlements`
- Use: `macos-signing/QuotaFloatSigning.xcodeproj`
- Install: `/Applications/Quota Float.app`

**Interfaces:**
- Consumes the final `.appex` and existing working Tauri host app.
- Produces a signed local app, recoverable backup, registered extension, and verified widget layouts.

- [ ] **Step 1: Repair the embed script**

Remove references to `QuotaFloatHost.entitlements`, hard-coded application identifiers, team identifiers, and `get-task-allow`. Keep only extension sandbox/network-client entitlements, the locally available Apple Development identity, inner-extension signing, outer-app signing, and deep verification.

- [ ] **Step 2: Run final automated verification**

```bash
npm test
npm run build
cd src-tauri && cargo test
cd ../macos-signing
xcodegen generate --spec project.yml
xcodebuild -project QuotaFloatSigning.xcodeproj -scheme QuotaFloatSigningHost -configuration Debug -derivedDataPath DerivedDataTests test
xcodebuild -quiet -project QuotaFloatSigning.xcodeproj -scheme QuotaFloatSigningHost -configuration Release -derivedDataPath DerivedDataUnsigned CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Expected: frontend tests PASS, Rust tests PASS, widget logic tests PASS, and Release widget build succeeds.

- [ ] **Step 3: Stage and sign a recoverable app copy**

Assert that `work/quota-float-install/Quota Float-six-themes-staged.app` and `work/quota-float-install/Quota Float-six-themes-old.appex` do not exist. Copy the current working `/Applications/Quota Float.app` to the staging path, move its old `.appex` to the explicit old-extension path, embed the Xcode-built extension, sign inner then outer, and run:

```bash
codesign --verify --deep --strict --verbose=2 "work/quota-float-install/Quota Float-six-themes-staged.app"
```

Expected: `valid on disk` and `satisfies its Designated Requirement`.

- [ ] **Step 4: Replace the installed app safely**

Assert that `work/quota-float-install/Quota Float-before-six-themes.app` does not exist. Quit Quota Float, move the existing app to that exact backup path, move the verified staged app to `/Applications/Quota Float.app`, register its `.appex` with `pluginkit -a`, and launch the app. If the exact backup path already exists, stop and choose a new explicit suffix before moving anything; never overwrite a backup.

- [ ] **Step 5: Verify host and extension processes**

```bash
curl -fsS http://127.0.0.1:47842/health
curl -fsS http://127.0.0.1:47842/snapshot
pluginkit -m -A -D -v -i app.quotafloat.desktop.widget
codesign --verify --deep --strict --verbose=2 "/Applications/Quota Float.app"
```

Expected: health is `ok`, snapshot contains status `ok`, plugin path points into `/Applications/Quota Float.app`, and signature verification passes.

- [ ] **Step 6: Verify the gallery and real widgets through macOS UI**

Refresh Notification Center and `chronod`, open Edit Widgets, select Quota Float, and confirm six configurations each provide small and medium previews. Add at least Pixel Quest, Fortune Vault, and Proud Robot. Confirm the live 86%-style weekly data, missing 5-hour neutral state, correct copy, and no clipping.

- [ ] **Step 7: Final regression and commit**

Keep one preferred medium widget installed unless the user requests more. Re-run health, snapshot, extension-process, and deep-signature checks.

```bash
git add scripts/embed-macos-widget.sh macos-signing/project.yml src-macos-widget src-macos-widget-tests
git commit -m "build(widget): ship six macOS quota themes"
```

Expected final state: six selectable themes, two sizes each, live weekly data, neutral missing-short-window behavior, cached fallback, valid signature, and a recoverable previous app backup.
