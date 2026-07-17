import Foundation
import WidgetKit

struct QuotaEntry: TimelineEntry {
    let date: Date
    let model: QuotaDisplayModel
}

struct QuotaTimelineProvider: TimelineProvider {
    private let store: QuotaSnapshotStore

    init(store: QuotaSnapshotStore = QuotaSnapshotStore()) {
        self.store = store
    }

    func placeholder(in context: Context) -> QuotaEntry {
        Self.previewEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuotaEntry) -> Void) {
        guard !context.isPreview else {
            completion(Self.previewEntry(date: Date()))
            return
        }

        Task {
            completion(await entry(date: Date()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotaEntry>) -> Void) {
        Task {
            let now = Date()
            let entry = await entry(date: now)
            completion(
                Timeline(
                    entries: [entry],
                    policy: .after(Self.nextRefresh(after: now))
                )
            )
        }
    }

    static func previewEntry(date: Date) -> QuotaEntry {
        let snapshot = ProviderSnapshot(
            provider: "codex",
            displayName: "CODEX",
            plan: "Plus",
            shortWindow: UsageWindow(
                remainingPercent: 82,
                resetsAt: nil,
                windowSeconds: 18_000
            ),
            weeklyWindow: UsageWindow(
                remainingPercent: 64,
                resetsAt: nil,
                windowSeconds: 604_800
            ),
            resetCredits: nil,
            resetCreditExpiresAt: [],
            updatedAt: ISO8601DateFormatter().string(from: date),
            status: "ok",
            message: nil
        )
        return QuotaEntry(
            date: date,
            model: QuotaDisplayModel(snapshot: snapshot, source: .live)
        )
    }

    static func nextRefresh(after date: Date) -> Date {
        date.addingTimeInterval(15 * 60)
    }

    private func entry(date: Date) async -> QuotaEntry {
        let result = await store.load(now: date)
        return QuotaEntry(
            date: date,
            model: QuotaDisplayModel(snapshot: result.snapshot, source: result.source)
        )
    }
}
