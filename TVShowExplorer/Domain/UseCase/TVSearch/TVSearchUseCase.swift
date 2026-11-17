//
//  TVSearchUseCase.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

// MARK: - TVSearchUseCaseProtocol

protocol TVSearchUseCaseProtocol: Sendable {
    func searchShows(for query: String) async throws -> [TVShow]
}

// MARK: - TVSearchUseCase

final class TVSearchUseCase: TVSearchUseCaseProtocol {

    private let repository: TVSearchRepositoryProtocol

    init(repository: TVSearchRepositoryProtocol) {
        self.repository = repository
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        try await repository.searchShows(for: query)
    }
}
