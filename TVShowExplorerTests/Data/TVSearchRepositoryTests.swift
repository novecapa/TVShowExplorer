//
//  TVSearchRepositoryTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class TVSearchRepositoryTests: XCTestCase {

    enum Constants {
        static let query = "breaking"
        static let otherQuery = "lost"
        static let timeToLive: TimeInterval = 180
    }

    var clock: TestClock!
    var cache: TVSearchCache!

    override func setUp() {
        super.setUp()
        let clock = TestClock()
        self.clock = clock
        self.cache = TVSearchCache(timeToLive: Constants.timeToLive, now: { clock.now })
    }

    override func tearDown() {
        clock = nil
        cache = nil
        super.tearDown()
    }

    func test_searchShows_firstSearch_callsRemote() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)

        // When
        let shows = try await repository.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries, [Constants.query])
        XCTAssertEqual(shows.map(\.id), [169])
        XCTAssertEqual(shows.map(\.name), ["Breaking Bad"])
    }

    func test_searchShows_secondSearchBeforeTTL_usesCacheWithoutCallingRemote() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        _ = try await repository.searchShows(for: Constants.query)

        // When
        clock.advance(by: Constants.timeToLive - 1)
        let shows = try await repository.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 1)
        XCTAssertEqual(shows.map(\.id), [169])
    }

    func test_searchShows_afterTTLExpires_callsRemoteAgainAndRestartsTTL() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)

        // When / Then
        _ = try await repository.searchShows(for: Constants.query) // 00:00
        var callCount = await remote.receivedQueries.count
        XCTAssertEqual(callCount, 1)

        clock.advance(by: 60)
        _ = try await repository.searchShows(for: Constants.query)
        clock.advance(by: 90)
        _ = try await repository.searchShows(for: Constants.query)
        callCount = await remote.receivedQueries.count
        XCTAssertEqual(callCount, 1)

        await remote.setResult(.success([.stub(id: 170, name: "Breaking Bad: Updated")]))
        clock.advance(by: 30)
        let refreshed = try await repository.searchShows(for: Constants.query)
        callCount = await remote.receivedQueries.count
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(refreshed.map(\.id), [170])

        clock.advance(by: 60)
        let cached = try await repository.searchShows(for: Constants.query)
        callCount = await remote.receivedQueries.count
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(cached, refreshed)
    }

    func test_searchShows_emptyResponse_isCached() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        _ = try await repository.searchShows(for: Constants.query)

        // When
        let shows = try await repository.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 1)
        XCTAssertTrue(shows.isEmpty)
    }

    func test_searchShows_remoteError_isPropagatedAndNotCached() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .failure(NetworkError.connectivity))
        let repository = TVSearchRepository(remote: remote, cache: cache)

        // When
        do {
            _ = try await repository.searchShows(for: Constants.query)
            XCTFail("Expected NetworkError.connectivity")
        } catch {
            XCTAssertEqual(error as? NetworkError, .connectivity)
        }

        // Then
        let cachedShows = await cache.shows(for: Constants.query)
        XCTAssertNil(cachedShows)

        await remote.setResult(.success([.stub(id: 169, name: "Breaking Bad")]))
        let shows = try await repository.searchShows(for: Constants.query)
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 2)
        XCTAssertEqual(shows.map(\.id), [169])
    }

    func test_searchShows_cancelledDuringRemoteCall_throwsCancellationErrorAndIsNotCached() async {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]),
                                        cancelsCallingTask: true)
        let repository = TVSearchRepository(remote: remote, cache: cache)

        // When
        let search = Task { try await repository.searchShows(for: Constants.query) }

        // Then
        do {
            _ = try await search.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let cachedShows = await cache.shows(for: Constants.query)
        XCTAssertNil(cachedShows)
    }

    func test_searchShows_cancelledTask_doesNotReturnCachedResults() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        let cachedShows = try await repository.searchShows(for: Constants.query)
        XCTAssertFalse(cachedShows.isEmpty)

        // When
        let search = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await repository.searchShows(for: Constants.query)
        }

        // Then
        do {
            _ = try await search.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 1)
    }

    func test_searchShows_differentQueries_keepIndependentEntries() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        let breaking = try await repository.searchShows(for: Constants.query)
        await remote.setResult(.success([.stub(id: 123, name: "Lost")]))
        let lost = try await repository.searchShows(for: Constants.otherQuery)

        // When
        let cachedBreaking = try await repository.searchShows(for: Constants.query)
        let cachedLost = try await repository.searchShows(for: Constants.otherQuery)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries, [Constants.query, Constants.otherQuery])
        XCTAssertEqual(cachedBreaking, breaking)
        XCTAssertEqual(cachedLost, lost)
        XCTAssertNotEqual(cachedBreaking, cachedLost)
    }

    func test_searchShows_cachedResponse_isEquivalentToOriginal() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad"),
                                                          .stub(id: 6061, name: "Breaking Point")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        let original = try await repository.searchShows(for: Constants.query)

        // When
        let cached = try await repository.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 1)
        XCTAssertEqual(cached, original)
    }
}

// MARK: - Stubs

private extension TVShowSearchResultDTO {
    static func stub(id: Int, name: String) -> TVShowSearchResultDTO {
        TVShowSearchResultDTO(score: 0.9,
                              show: TVShowDTO(id: id,
                                              name: name,
                                              type: "Scripted",
                                              language: "English",
                                              genres: ["Drama", "Crime"],
                                              status: "Ended",
                                              runtime: 60,
                                              averageRuntime: 60,
                                              premiered: "2008-01-20",
                                              ended: "2013-09-29",
                                              officialSite: "https://www.amc.com/shows/breaking-bad",
                                              summary: "<p><b>\(name)</b> follows a chemistry teacher.</p>",
                                              rating: TVRatingDTO(average: 9.2),
                                              image: TVImageDTO(medium: URL(string: "https://static.tvmaze.com/medium.jpg"),
                                                                original: URL(string: "https://static.tvmaze.com/original.jpg")),
                                              schedule: TVScheduleDTO(time: "22:00", days: ["Sunday"]),
                                              network: TVNetworkDTO(name: "AMC"),
                                              webChannel: nil))
    }
}
