import Foundation
import XCTest

final class QuotaSnapshotStoreTests: XCTestCase {
    private let cacheKey = "app.quotafloat.widget.last-successful-snapshot"
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "QuotaSnapshotStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        SnapshotURLProtocol.reset()
    }

    override func tearDown() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
        suiteName = nil
        defaults = nil
        SnapshotURLProtocol.reset()
        super.tearDown()
    }

    func testSuccessfulResponseReturnsFirstSnapshotAsLiveAndCachesIt() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let first = snapshot(plan: "Plus")
        let second = snapshot(plan: "Pro")
        SnapshotURLProtocol.configure(response: .http(statusCode: 200, body: try JSONEncoder().encode([first, second])))

        let result = await makeStore().load(now: now)

        XCTAssertEqual(result, QuotaLoadResult(snapshot: first, source: .live))
        XCTAssertEqual(SnapshotURLProtocol.requestCount, 1)

        let cacheData = try XCTUnwrap(defaults.data(forKey: cacheKey))
        XCTAssertEqual(try JSONDecoder().decode(CachedSnapshot.self, from: cacheData), CachedSnapshot(snapshot: first, cachedAt: now))
    }

    func testTimeoutReturnsFreshCachedSnapshot() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cached = CachedSnapshot(snapshot: snapshot(), cachedAt: now.addingTimeInterval(-7_200))
        defaults.set(try JSONEncoder().encode(cached), forKey: cacheKey)
        SnapshotURLProtocol.configure(response: .error(URLError(.timedOut)))

        let result = await makeStore().load(now: now)

        XCTAssertEqual(result, QuotaLoadResult(snapshot: cached.snapshot, source: .cached(savedAt: cached.cachedAt, isOlderThanOneDay: false)))
        XCTAssertEqual(SnapshotURLProtocol.requestCount, 1)
    }

    func testServerErrorReturnsOldCachedSnapshot() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let cached = CachedSnapshot(snapshot: snapshot(), cachedAt: now.addingTimeInterval(-90_000))
        defaults.set(try JSONEncoder().encode(cached), forKey: cacheKey)
        SnapshotURLProtocol.configure(response: .http(statusCode: 500, body: Data()))

        let result = await makeStore().load(now: now)

        XCTAssertEqual(result, QuotaLoadResult(snapshot: cached.snapshot, source: .cached(savedAt: cached.cachedAt, isOlderThanOneDay: true)))
        XCTAssertEqual(SnapshotURLProtocol.requestCount, 1)
    }

    func testInvalidJSONWithoutCacheReturnsUnavailableSnapshot() async {
        SnapshotURLProtocol.configure(response: .http(statusCode: 200, body: Data("not-json".utf8)))

        let result = await makeStore().load(now: Date(timeIntervalSince1970: 1_000_000))

        XCTAssertEqual(result.source, .unavailable(message: "请打开 Quota Float 刷新额度"))
        XCTAssertEqual(result.snapshot.status, "unavailable")
        XCTAssertEqual(result.snapshot.message, "请打开 Quota Float 刷新额度")
        XCTAssertEqual(SnapshotURLProtocol.requestCount, 1)
    }

    private func makeStore() -> QuotaSnapshotStore {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SnapshotURLProtocol.self]
        return QuotaSnapshotStore(
            session: URLSession(configuration: configuration),
            defaults: defaults,
            endpoint: URL(string: "https://snapshot.test/snapshot")!
        )
    }

    private func snapshot(plan: String? = "Plus") -> ProviderSnapshot {
        ProviderSnapshot(
            provider: "codex",
            displayName: "CODEX",
            plan: plan,
            shortWindow: UsageWindow(remainingPercent: 82, resetsAt: "2026-07-18T12:34:56Z", windowSeconds: 18_000),
            weeklyWindow: UsageWindow(remainingPercent: 64, resetsAt: "2026-07-19T12:34:56Z", windowSeconds: 604_800),
            resetCredits: 3,
            resetCreditExpiresAt: ["2026-07-20T12:34:56Z"],
            updatedAt: "2026-07-18T12:34:56Z",
            status: "ok",
            message: nil
        )
    }
}

private final class SnapshotURLProtocol: URLProtocol {
    enum Response {
        case http(statusCode: Int, body: Data)
        case error(Error)
    }

    private static let lock = NSLock()
    private static var response: Response?
    private(set) static var requestCount = 0

    static func configure(response: Response) {
        lock.lock()
        self.response = response
        lock.unlock()
    }

    static func reset() {
        lock.lock()
        response = nil
        requestCount = 0
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        Self.requestCount += 1
        let response = Self.response
        Self.lock.unlock()

        guard let response else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch response {
        case let .http(statusCode, body):
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .error(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
