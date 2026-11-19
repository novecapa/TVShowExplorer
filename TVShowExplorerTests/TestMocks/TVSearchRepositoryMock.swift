//
//  TVSearchRepositoryMock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 19/11/2026.
//

@testable import TVShowExplorer

actor TVSearchRepositoryMock: TVSearchRepositoryProtocol {

    private(set) var receivedQueries: [String] = []
    private let result: Result<[TVShow], Error>

    init(result: Result<[TVShow], Error>) {
        self.result = result
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        receivedQueries.append(query)
        return try result.get()
    }
}
