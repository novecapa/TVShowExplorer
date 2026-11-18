//
//  TVSearchUseCaseMock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

@testable import TVShowExplorer

actor TVSearchUseCaseMock: TVSearchUseCaseProtocol {

    private(set) var receivedQueries: [String] = []
    private var results: [String: Result<[TVShow], Error>]
    private let heldQueries: Set<String>
    private var heldRequests: [String: CheckedContinuation<Void, Never>] = [:]
    private var heldRequestArrivals: [String: CheckedContinuation<Void, Never>] = [:]

    init(results: [String: Result<[TVShow], Error>] = [:], holding heldQueries: String...) {
        self.results = results
        self.heldQueries = Set(heldQueries)
    }

    func setResult(_ result: Result<[TVShow], Error>, for query: String) {
        results[query] = result
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        receivedQueries.append(query)
        if heldQueries.contains(query) {
            heldRequestArrivals.removeValue(forKey: query)?.resume()
            await withCheckedContinuation { heldRequests[query] = $0 }
        }
        return try (results[query] ?? .success([])).get()
    }

    func waitForHeldQuery(_ query: String) async {
        guard heldRequests[query] == nil else { return }
        await withCheckedContinuation { heldRequestArrivals[query] = $0 }
    }

    func releaseHeldQuery(_ query: String) {
        heldRequests.removeValue(forKey: query)?.resume()
    }
}
