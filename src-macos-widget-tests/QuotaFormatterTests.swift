import XCTest

final class QuotaFormatterTests: XCTestCase {
    func testPercentRoundsToNearestWholeNumber() {
        XCTAssertEqual(QuotaFormatter.percent(86.4), "86%")
        XCTAssertEqual(QuotaFormatter.percent(86.5), "87%")
    }

    func testPercentUsesPlaceholderForMissingValue() {
        XCTAssertEqual(QuotaFormatter.percent(nil), "--")
    }

    func testResetTextFormatsISO8601DateWithoutFractionalSeconds() {
        XCTAssertEqual(QuotaFormatter.resetText("2026-07-18T12:34:56Z"), "7月18日 20:34 重置")
    }

    func testResetTextFormatsISO8601DateWithFractionalSeconds() {
        XCTAssertEqual(QuotaFormatter.resetText("2026-07-18T12:34:56.789Z"), "7月18日 20:34 重置")
    }

    func testResetTextUsesUnknownMessageForMissingOrInvalidDate() {
        XCTAssertEqual(QuotaFormatter.resetText(nil), "重置时间未知")
        XCTAssertEqual(QuotaFormatter.resetText("not-a-date"), "重置时间未知")
    }

    func testSourceTextOmitsLiveDataStatus() {
        XCTAssertNil(QuotaFormatter.sourceText(.live))
    }

    func testSourceTextMarksFreshCachedData() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(
            QuotaFormatter.sourceText(.cached(savedAt: now.addingTimeInterval(-86_400), isOlderThanOneDay: false), now: now),
            "缓存数据"
        )
    }

    func testSourceTextMarksOldCachedData() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(
            QuotaFormatter.sourceText(.cached(savedAt: now.addingTimeInterval(-86_401), isOlderThanOneDay: false), now: now),
            "数据较旧"
        )
    }

    func testSourceTextUsesUnavailableMessageOrFallback() {
        XCTAssertEqual(QuotaFormatter.sourceText(.unavailable(message: "服务暂不可用")), "服务暂不可用")
        XCTAssertEqual(QuotaFormatter.sourceText(.unavailable(message: nil)), "请打开 Quota Float")
    }
}
