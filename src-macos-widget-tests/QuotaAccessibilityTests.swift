import Foundation
import XCTest

final class QuotaAccessibilityTests: XCTestCase {
    func testEachThemeSummaryIncludesPlanWindowsPercentMoodAndResetTimes() {
        let model = makeModel(short: 86, weekly: 47)

        for theme in QuotaThemeID.allCases {
            let summary = QuotaAccessibility.summary(theme: theme, model: model)

            XCTAssertTrue(summary.contains("计划 PLUS ACCESSIBILITY PLAN"), "Missing plan for \(theme): \(summary)")
            XCTAssertTrue(summary.contains("5 小时额度"), "Missing short-window label for \(theme): \(summary)")
            XCTAssertTrue(summary.contains("剩余 86%"), "Missing exact short-window percent for \(theme): \(summary)")
            XCTAssertTrue(summary.contains(theme.copy(for: .abundant).headline), "Missing abundant headline for \(theme): \(summary)")
            XCTAssertTrue(summary.contains(QuotaFormatter.resetText(shortReset)), "Missing short reset time for \(theme): \(summary)")
            XCTAssertTrue(summary.contains("每周额度"), "Missing weekly-window label for \(theme): \(summary)")
            XCTAssertTrue(summary.contains("剩余 47%"), "Missing exact weekly percent for \(theme): \(summary)")
            XCTAssertTrue(summary.contains(theme.copy(for: .steady).headline), "Missing steady headline for \(theme): \(summary)")
            XCTAssertTrue(summary.contains(QuotaFormatter.resetText(weeklyReset)), "Missing weekly reset time for \(theme): \(summary)")
        }
    }

    func testEachThemeSummaryUsesUnavailableWordingWithoutInventingZeroPercent() {
        let model = makeModel(short: nil, weekly: nil, source: .unavailable(message: nil))

        for theme in QuotaThemeID.allCases {
            let summary = QuotaAccessibility.summary(theme: theme, model: model)

            XCTAssertTrue(summary.contains("5 小时额度，\(theme.emptyCopy)"), "Missing short unavailable wording for \(theme): \(summary)")
            XCTAssertTrue(summary.contains("每周额度，\(theme.emptyCopy)"), "Missing weekly unavailable wording for \(theme): \(summary)")
            XCTAssertFalse(summary.contains("0%"), "Unavailable data became zero for \(theme): \(summary)")
        }
    }

    func testSummaryIncludesCacheStatusWhenUsingCachedData() {
        let model = makeModel(
            short: 18,
            weekly: 6,
            source: .cached(savedAt: Date().addingTimeInterval(-7_200), isOlderThanOneDay: false)
        )

        for theme in QuotaThemeID.allCases {
            XCTAssertTrue(
                QuotaAccessibility.summary(theme: theme, model: model).contains("缓存数据"),
                "Missing cache status for \(theme)"
            )
        }
    }

    func testUnavailablePercentStillIncludesResetTimeWhenResetIsPresent() {
        let model = makeModel(short: .nan, weekly: 47)

        for theme in QuotaThemeID.allCases {
            let summary = QuotaAccessibility.summary(theme: theme, model: model)

            XCTAssertTrue(summary.contains("5 小时额度，\(theme.emptyCopy)"), "Missing unavailable wording for \(theme): \(summary)")
            XCTAssertTrue(summary.contains(QuotaFormatter.resetText(shortReset)), "Missing available reset time for \(theme): \(summary)")
        }
    }

    private let shortReset = "2026-07-18T10:30:00Z"
    private let weeklyReset = "2026-07-21T08:00:00Z"

    private func makeModel(
        short: Double?,
        weekly: Double?,
        source: QuotaSource = .live
    ) -> QuotaDisplayModel {
        QuotaDisplayModel(
            snapshot: ProviderSnapshot(
                provider: "codex",
                displayName: "CODEX",
                plan: "PLUS ACCESSIBILITY PLAN",
                shortWindow: short.map {
                    UsageWindow(remainingPercent: $0, resetsAt: shortReset, windowSeconds: 18_000)
                },
                weeklyWindow: weekly.map {
                    UsageWindow(remainingPercent: $0, resetsAt: weeklyReset, windowSeconds: 604_800)
                },
                resetCredits: nil,
                resetCreditExpiresAt: [],
                updatedAt: "2026-07-18T07:00:00Z",
                status: "ok",
                message: nil
            ),
            source: source
        )
    }
}
