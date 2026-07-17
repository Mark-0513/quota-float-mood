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
