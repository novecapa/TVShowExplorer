//
//  TVSearchRepositoryProtocol.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

// MARK: - TVSearchRepositoryProtocol

protocol TVSearchRepositoryProtocol: Sendable {
    func searchShows(for query: String) async throws -> [TVShow]
}
