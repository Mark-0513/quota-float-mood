import Foundation

struct QuotaLoadResult: Equatable {
    let snapshot: ProviderSnapshot
    let source: QuotaSource
}

struct QuotaSnapshotStore {
    private static let cacheKey = "app.quotafloat.widget.last-successful-snapshot"
    private static let unavailableMessage = "请打开 Quota Float 刷新额度"
    private static let oneDay: TimeInterval = 86_400

    private let session: URLSession
    private let defaults: UserDefaults
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        defaults: UserDefaults = .standard,
        endpoint: URL = URL(string: "http://127.0.0.1:47842/snapshot")!
    ) {
        self.session = session
        self.defaults = defaults
        self.endpoint = endpoint
    }

    func load(now: Date = Date()) async -> QuotaLoadResult {
        do {
            var request = URLRequest(url: endpoint)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 4

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let snapshot = try JSONDecoder().decode([ProviderSnapshot].self, from: data).first
            else {
                return cachedResult(now: now)
            }

            store(snapshot, cachedAt: now)
            return QuotaLoadResult(snapshot: snapshot, source: .live)
        } catch {
            return cachedResult(now: now)
        }
    }

    private func store(_ snapshot: ProviderSnapshot, cachedAt: Date) {
        let cached = CachedSnapshot(snapshot: snapshot, cachedAt: cachedAt)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: Self.cacheKey)
    }

    private func cachedResult(now: Date) -> QuotaLoadResult {
        guard let data = defaults.data(forKey: Self.cacheKey),
              let cached = try? JSONDecoder().decode(CachedSnapshot.self, from: data)
        else {
            let snapshot = ProviderSnapshot.unavailable(message: Self.unavailableMessage)
            return QuotaLoadResult(snapshot: snapshot, source: .unavailable(message: Self.unavailableMessage))
        }

        let isOlderThanOneDay = now.timeIntervalSince(cached.cachedAt) > Self.oneDay
        return QuotaLoadResult(
            snapshot: cached.snapshot,
            source: .cached(savedAt: cached.cachedAt, isOlderThanOneDay: isOlderThanOneDay)
        )
    }
}
