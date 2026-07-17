import Foundation

enum QuotaFormatter {
    static func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "--" }
        return "\(Int(value.rounded()))%"
    }

    static func resetText(_ rawDate: String?) -> String {
        guard let rawDate, let date = parseISO8601(rawDate) else {
            return "重置时间未知"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm 重置"
        return formatter.string(from: date)
    }

    static func sourceText(_ source: QuotaSource, now: Date = Date()) -> String? {
        switch source {
        case .live:
            return nil
        case let .cached(savedAt, isOlderThanOneDay):
            let isOverOneDayOld = now.timeIntervalSince(savedAt) > 86_400
            return isOlderThanOneDay || isOverOneDayOld ? "数据较旧" : "缓存数据"
        case let .unavailable(message):
            return message?.isEmpty == false ? message : "请打开 Quota Float"
        }
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
