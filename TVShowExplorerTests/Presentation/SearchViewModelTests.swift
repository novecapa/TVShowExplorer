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

    // MARK: - States

    func test_init_isIdleWithoutSearching() async {
        // Given
        let useCase = TVSearchUseCaseMock()

        // When
        let viewModel = makeViewModel(useCase: useCase)

        // Then
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.searchTask)
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [])
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

    func test_search_trimsQueryBeforeCallingUseCase() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .success([Constants.breakingBad])])
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = "  \(Constants.query) \n"
        await viewModel.searchTask?.value

        // Then
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
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

    func test_retry_afterError_searchesAgainAndShowsResults() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(NetworkError.connectivity)])
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        XCTAssertEqual(viewModel.state, .error)
        await useCase.setResult(.success([Constants.breakingBad]), for: Constants.query)

        // When
        viewModel.retry()
        XCTAssertEqual(viewModel.state, .loading)
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query, Constants.query])
    }

    func test_newQuery_afterError_showsResults() async {
        // Given
        let useCase = TVSearchUseCaseMock(results: [Constants.partialQuery: .failure(NetworkError.rateLimited),
                                                    Constants.query: .success([Constants.breakingBad])])
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        await viewModel.searchTask?.value
        XCTAssertEqual(viewModel.state, .error)

        // When
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
    }

    // MARK: - Debounce

    func test_debounce_doesNotSearchBeforeIntervalElapses() async {
        // Given: a debounce far longer than the test
        let useCase = TVSearchUseCaseMock()
        let viewModel = SearchViewModel(useCase: useCase, debounce: .seconds(60))

        // When
        viewModel.query = Constants.query
        let pendingSearch = viewModel.searchTask
        await Task.yield()

        // Then
        XCTAssertEqual(viewModel.state, .loading)
        var queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [])

        viewModel.query = ""
        await pendingSearch?.value
        queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [], "A search cancelled during its debounce must not reach the use case")
    }

    func test_debounce_waitsAtLeastTheConfiguredInterval() async {
        // Given
        let debounce = Duration.milliseconds(100)
        let useCase = TVSearchUseCaseMock()
        let viewModel = SearchViewModel(useCase: useCase, debounce: debounce)
        let clock = ContinuousClock()
        let start = clock.now

        // When
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // Then: only a lower bound, because sleeping never ends early but can end late
        XCTAssertGreaterThanOrEqual(clock.now - start, debounce)
        let queries = await useCase.receivedQueries
        XCTAssertEqual(queries, [Constants.query])
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

    // MARK: - Concurrency

    func test_staleResponse_doesNotOverwriteNewerResults() async {
        // Given: the first search is in flight and its use case ignores cancellation
        let useCase = TVSearchUseCaseMock(results: [Constants.partialQuery: .success([Constants.staleShow]),
                                                    Constants.query: .success([Constants.breakingBad])],
                                          holding: Constants.partialQuery)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        let staleSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.partialQuery)

        // When: a newer search finishes first, then the old response arrives
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        await useCase.releaseHeldQuery(Constants.partialQuery)
        await staleSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
    }

    func test_staleError_doesNotOverwriteNewerResults() async {
        // Given: the first search is in flight and will fail
        let useCase = TVSearchUseCaseMock(results: [Constants.partialQuery: .failure(NetworkError.serverError),
                                                    Constants.query: .success([Constants.breakingBad])],
                                          holding: Constants.partialQuery)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        let staleSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.partialQuery)

        // When: a newer search finishes first, then the old error arrives
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        await useCase.releaseHeldQuery(Constants.partialQuery)
        await staleSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
    }

    func test_staleResponse_whileNewerSearchIsInFlight_keepsLoadingState() async {
        // Given: both searches reach the use case and wait there
        let useCase = TVSearchUseCaseMock(results: [Constants.partialQuery: .success([Constants.staleShow]),
                                                    Constants.query: .success([Constants.breakingBad])],
                                          holding: Constants.partialQuery, Constants.query)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.partialQuery
        let staleSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.partialQuery)
        viewModel.query = Constants.query
        let currentSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.query)

        // When: the old response arrives before the newer one
        await useCase.releaseHeldQuery(Constants.partialQuery)
        await staleSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .loading)
        await useCase.releaseHeldQuery(Constants.query)
        await currentSearch?.value
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
    }

    func test_cancelledSearch_doesNotShowError() async {
        // Given: the search is in flight and will fail with a cancellation error
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(CancellationError())],
                                          holding: Constants.query)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        let cancelledSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.query)

        // When
        viewModel.query = ""
        await useCase.releaseHeldQuery(Constants.query)
        await cancelledSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_cancellationErrorWithoutCancelledSearch_showsError() async {
        // Given: a dependency throws a cancellation error although the search itself is still current
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .failure(CancellationError())])
        let viewModel = makeViewModel(useCase: useCase)

        // When
        viewModel.query = Constants.query
        await viewModel.searchTask?.value

        // Then
        XCTAssertEqual(viewModel.state, .error)
    }

    func test_clearingQuery_whileSearchIsInFlight_ignoresLateResults() async {
        // Given: the search is in flight and its use case ignores cancellation
        let useCase = TVSearchUseCaseMock(results: [Constants.query: .success([Constants.breakingBad])],
                                          holding: Constants.query)
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.query = Constants.query
        let pendingSearch = viewModel.searchTask
        await useCase.waitForHeldQuery(Constants.query)

        // When
        viewModel.query = ""
        await useCase.releaseHeldQuery(Constants.query)
        await pendingSearch?.value

        // Then
        XCTAssertEqual(viewModel.state, .idle)
    }

    // MARK: - Recent searches

    func test_completedSearch_isRecordedOnlyWhenAResultIsSelected() async {
        // Given
        let viewModel = makeViewModel(returningResultsFor: [Constants.query])
        viewModel.query = Constants.query
        await viewModel.searchTask?.value
        XCTAssertEqual(viewModel.state, .loaded([Constants.breakingBad]))
        XCTAssertEqual(viewModel.recentSearches, [])

        // When
        viewModel.recordSelectedSearch()

        // Then
        XCTAssertEqual(viewModel.recentSearches, [Constants.query])
    }

    func test_recordSelectedSearch_withExistingQueryInAnotherCase_movesItFirstWithoutDuplicates() async {
        // Given
        let viewModel = makeViewModel(returningResultsFor: ["breaking bad", "friends", "dexter", "Friends"])
        for query in ["breaking bad", "friends", "dexter"] {
            await selectResult(for: query, in: viewModel)
        }
        XCTAssertEqual(viewModel.recentSearches, ["dexter", "friends", "breaking bad"])

        // When
        await selectResult(for: "Friends", in: viewModel)

        // Then: the entry keeps the latest text
        XCTAssertEqual(viewModel.recentSearches, ["Friends", "dexter", "breaking bad"])
    }

    func test_recordSelectedSearch_trimsWhitespace() async {
        // Given
        let viewModel = makeViewModel(returningResultsFor: ["dexter"])

        // When
        await selectResult(for: "  dexter \n", in: viewModel)

        // Then
        XCTAssertEqual(viewModel.recentSearches, ["dexter"])
    }

    func test_recordSelectedSearch_whileNewQueryIsLoading_recordsNothing() async {
        // Given: results for "dexter" are shown and the user starts typing another query
        let viewModel = makeViewModel(returningResultsFor: ["dexter"])
        viewModel.query = "dexter"
        await viewModel.searchTask?.value
        viewModel.query = "fri"
        XCTAssertEqual(viewModel.state, .loading)

        // When
        viewModel.recordSelectedSearch()

        // Then: neither the hidden results' query nor the unfinished one is saved
        XCTAssertEqual(viewModel.recentSearches, [])
    }

    func test_recordSelectedSearch_keepsTheFiveMostRecentQueries() async {
        // Given
        let queries = ["lost", "dark", "fargo", "friends", "dexter", "the office"]
        let viewModel = makeViewModel(returningResultsFor: queries)

        // When
        for query in queries {
            await selectResult(for: query, in: viewModel)
        }

        // Then
        XCTAssertEqual(viewModel.recentSearches, ["the office", "dexter", "friends", "fargo", "dark"])
    }
}

// MARK: - Helpers

private extension SearchViewModelTests {
    func makeViewModel(useCase: TVSearchUseCaseMock) -> SearchViewModel {
        SearchViewModel(useCase: useCase, debounce: .zero)
    }

    func makeViewModel(returningResultsFor queries: [String]) -> SearchViewModel {
        let results: [String: Result<[TVShow], Error>] = Dictionary(
            uniqueKeysWithValues: queries.map { ($0, .success([Constants.breakingBad])) }
        )
        return makeViewModel(useCase: TVSearchUseCaseMock(results: results))
    }

    /// Searches `query` and opens one of its results.
    func selectResult(for query: String, in viewModel: SearchViewModel) async {
        viewModel.query = query
        await viewModel.searchTask?.value
        viewModel.recordSelectedSearch()
    }
}
