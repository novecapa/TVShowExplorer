//
//  TVSearchUseCaseTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 19/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class TVSearchUseCaseTests: XCTestCase {

    enum Constants {
        static let query = "breaking"
    }

    private struct RepositoryError: Error, Equatable {}

    func test_searchShows_forwardsQueryAndReturnsRepositoryShows() async throws {
        // Given
        let shows = [TVShow.stub(id: 169, name: "Breaking Bad"), TVShow.stub(id: 6061, name: "Breaking Point")]
        let repository = TVSearchRepositoryMock(result: .success(shows))
        let useCase = TVSearchUseCase(repository: repository)

        // When
        let result = try await useCase.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await repository.receivedQueries
        XCTAssertEqual(receivedQueries, [Constants.query])
        XCTAssertEqual(result, shows)
    }

    func test_searchShows_whenRepositoryFails_propagatesError() async {
        // Given
        let repository = TVSearchRepositoryMock(result: .failure(RepositoryError()))
        let useCase = TVSearchUseCase(repository: repository)

        // When / Then
        do {
            let shows = try await useCase.searchShows(for: Constants.query)
            XCTFail("Expected RepositoryError, got \(shows)")
        } catch {
            XCTAssertEqual(error as? RepositoryError, RepositoryError())
        }
    }
}
