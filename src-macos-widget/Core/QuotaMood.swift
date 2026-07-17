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
