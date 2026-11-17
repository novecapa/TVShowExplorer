//
//  TVSearchRemoteMock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation
@testable import TVShowExplorer

actor TVSearchRemoteMock: TVSearchRemoteProtocol {

    private(set) var receivedQueries: [String] = []
    private var result: Result<[TVShowSearchResultDTO], Error>
    private let cancelsCallingTask: Bool

    init(result: Result<[TVShowSearchResultDTO], Error>, cancelsCallingTask: Bool = false) {
        self.result = result
        self.cancelsCallingTask = cancelsCallingTask
    }

    func setResult(_ result: Result<[TVShowSearchResultDTO], Error>) {
        self.result = result
    }

    func searchShows(for query: String) async throws -> [TVShowSearchResultDTO] {
        receivedQueries.append(query)
        if cancelsCallingTask {
            withUnsafeCurrentTask { $0?.cancel() }
        }
        return try result.get()
    }
}
