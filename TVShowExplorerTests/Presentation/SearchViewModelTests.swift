//
//  SearchViewModelTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import XCTest
@testable import TVShowExplorer

@MainActor
final class SearchViewModelTests: XCTestCase {

    enum Constants {
        static let query = "breaking"
        static let partialQuery = "bre"
        static let breakingBad = TVShow.stub(id: 169, name: "Breaking Bad")
        static let staleShow = TVShow.stub(id: 1, name: "Bread")
    }

    func test_search_withResults_showsLoadedState() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .success([Constants.breakingBad])])
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = Constants.query
        XCTAssertEqual(viewModel.state, .loading)
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
    }

    func test_search_withNoMatches_showsEmptyState() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .success([])])
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_search_whenUseCaseFails_showsErrorState() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(NetworkError.serverError)])
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .error)
    }

    func test_search_withBlankQuery_doesNotCallUseCase() async {
        // Given
        let useCase = TVSearchUseCaseMock()
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = "   "

        // Then
        XCTAssertNil(viewModel.searchTask)
        XCTAssertEqual(viewModel.state, .idle)
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [])
    }

    func test_debounce_whenTypingQuickly_searchesOnlyLastQuery() async {
        // Given: the production debounce
        let useCase = TVSearchUseCaseMock()
        let viewModel = SearchViewModel(useCase: useCase)

        // When: each yield lets the search start and wait in its debounce before the next key
        for text in ["b", "br", "bre", "brea", Constants.query] {
            viewModel.query = text
            await Task.yield()
        }
        await viewModel.searchTask?.value

        // Then
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
    }

    func test_newSearch_cancelsPreviousSearch() async {
        // Given
        let useCase = TVSearchUseCaseMock()
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        let previousSearch = viewModel.searchTask

        // When
        viewModel.query = Constants.query

        // Then
        XCTAssertEqual(previousSearch?.isCancelled, true)
        await previousSearch?.value
        await viewModel.searchTask?.value
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
    }

    func test_staleResponse_doesNotOverwriteNewerResults() async {
        // Given: the first search is in flight and its use case ignores cancellation
        let useCase = TVSearchUseCaseMock(results: [Constants.partialQuery: .success([Constants.staleShow]),
                                                    Constants.query: .success([Constants.breakingBad])],
                                          holding: Constants.partialQuery)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        let staleSearch = viewModel.searchTask
        await useCase.waitForHeldQuery()

        // When: a newer search finishes first, then the old response arrives
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        await useCase.releaseHeldQuery()
        await staleSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
    }

    func test_cancelledSearch_doesNotShowError() async {
        // Given: the search is in flight and will fail with a cancellation error
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(CancellationError())],
                                          holding: Constants.query)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        let cancelledSearch = viewModel.searchTask
        await useCase.waitForHeldQuery()

        // When
        viewModel.query = ""
        await useCase.releaseHeldQuery()
        await cancelledSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_clearingQuery_removesPreviousResults() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .success([Constants.breakingBad])])
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))

        // When
        viewModel.query = ""

        // Then
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.searchTask)
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
    }

    func test_retry_afterError_searchesAgain() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(NetworkError.connectivity)])
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // When
        viewModel.retry()
        await viewModel.searchTask?.value

        // Then
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query, Constants.query])
    }
}

// MARK: - Helpers

private extension SearchViewModelTests {
    func makeViewModel(useCase: TVSearchUseCaseMock) -> SearchViewModel {
        SearchViewModel(useCase: useCase, debounce: .zero)
    }
}
