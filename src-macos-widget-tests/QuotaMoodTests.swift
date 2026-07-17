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
