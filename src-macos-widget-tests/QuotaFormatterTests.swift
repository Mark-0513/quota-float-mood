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
        let rawDate = "2026-07-18T12:34:56Z"
        XCTAssertEqual(QuotaFormatter.resetText(rawDate), expectedResetText(for: rawDate))
    }

    func testResetTextFormatsISO8601DateWithFractionalSeconds() {
        let rawDate = "2026-07-18T12:34:56.789Z"
        XCTAssertEqual(QuotaFormatter.resetText(rawDate), expectedResetText(for: rawDate))
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

    private func expectedResetText(for rawDate: String) -> String {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fractional.date(from: rawDate) ?? ISO8601DateFormatter().date(from: rawDate) else {
            XCTFail("Expected fixed ISO-8601 date to parse")
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm 重置"
        return formatter.string(from: date)
    }
}
