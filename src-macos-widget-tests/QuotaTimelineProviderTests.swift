import XCTest

final class QuotaTimelineProviderTests: XCTestCase {
    func testPreviewEntryUsesExpectedQuotaValues() {
        let date = Date(timeIntervalSince1970: 1_000_000)

        let entry = QuotaTimelineProvider.previewEntry(date: date)

        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.model.short.remainingPercent, 82)
        XCTAssertEqual(entry.model.weekly.remainingPercent, 64)
    }

    func testNextRefreshIsFifteenMinutesLater() {
        let date = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(
            QuotaTimelineProvider.nextRefresh(after: date),
            date.addingTimeInterval(15 * 60)
        )
    }
}
