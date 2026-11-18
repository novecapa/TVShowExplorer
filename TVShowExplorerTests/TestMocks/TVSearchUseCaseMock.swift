//
//  TVSearchUseCaseMock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation
@testable import TVShowExplorer

actor TVSearchUseCaseMock: TVSearchUseCaseProtocol {

    private(set) var receivedQueries: [String] = []
    private let results: [String: Result<[TVShow], Error>]
    private let heldQuery: String?
    private var heldRequest: CheckedContinuation<Void, Never>?
    private var heldRequestArrival: CheckedContinuation<Void, Never>?

    init(results: [String: Result<[TVShow], Error>] = [:], holding heldQuery: String? = nil) {
        self.results = results
        self.heldQuery = heldQuery
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        receivedQueries.append(query)
        if query == heldQuery {
            heldRequestArrival?.resume()
            heldRequestArrival = nil
            await withCheckedContinuation { heldRequest = $0 }
        }
        return try (results[query] ?? .success([])).get()
    }

    func waitForHeldQuery() async {
        guard heldRequest == nil else { return }
        await withCheckedContinuation { heldRequestArrival = $0 }
    }

    func releaseHeldQuery() {
        heldRequest?.resume()
        heldRequest = nil
    }
}
