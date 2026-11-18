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
    }

    func test_searchShows_secondSearchBeforeTTL_usesCacheWithoutCallingRemote() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad"),
                                                          .stub(id: 6061, name: "Breaking Point")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)
        let original = try await repository.searchShows(for: Constants.query)

        // When
        clock.advance(by: Constants.timeToLive - 1)
        let cached = try await repository.searchShows(for: Constants.query)

        // Then
        let receivedQueries = await remote.receivedQueries
        XCTAssertEqual(receivedQueries.count, 1)
        XCTAssertEqual(cached, original)
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

    func test_searchShows_mapsShowDTOToEntity() async throws {
        // Given
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad")]))
        let repository = TVSearchRepository(remote: remote, cache: cache)

        // When
        let shows = try await repository.searchShows(for: Constants.query)

        // Then
        let expected = TVShow(id: 169,
                              name: "Breaking Bad",
                              genres: ["Drama", "Crime"],
                              premiered: "2008-01-20",
                              ended: "2013-09-29",
                              summary: "Breaking Bad follows a chemistry teacher.",
                              rating: 9.2,
                              mediumImageURL: URL(string: "https://static.tvmaze.com/medium.jpg"),
                              originalImageURL: URL(string: "https://static.tvmaze.com/original.jpg"),
                              channel: "AMC")
        XCTAssertEqual(shows, [expected])
    }

    func test_searchShows_mapsMissingFieldsToNilAndFallsBackToWebChannel() async throws {
        // Given: a web show without network, rating or image
        let dto = TVShowSearchResultDTO.stub(id: 1,
                                             name: "Breaking Point",
                                             network: nil,
                                             webChannel: "Netflix",
                                             rating: nil,
                                             image: nil)
        let repository = TVSearchRepository(remote: TVSearchRemoteMock(result: .success([dto])), cache: cache)

        // When
        let shows = try await repository.searchShows(for: Constants.query)

        // Then
        let show = try XCTUnwrap(shows.first)
        XCTAssertEqual(show.channel, "Netflix")
        XCTAssertNil(show.rating)
        XCTAssertNil(show.mediumImageURL)
        XCTAssertNil(show.originalImageURL)
    }

    func test_searchShows_mapsSummaryHTMLToPlainTextKeepingParagraphs() async throws {
        // Given
        let html = """
        <p>Walter <b>White</b> is a <i>chemistry</i> <strong>teacher</strong>.</p>
        <p>His life changes <em>dramatically</em>.<br>Forever.</p>
        """

        // When
        let summary = try await mappedSummary(from: html)

        // Then
        XCTAssertEqual(summary, "Walter White is a chemistry teacher.\nHis life changes dramatically.\nForever.")
    }

    func test_searchShows_decodesCommonHTMLEntitiesInSummary() async throws {
        // When
        let summary = try await mappedSummary(from: "<p>Walter &amp; Jesse&#39;s &quot;business&quot;&nbsp;&lt;3&gt;</p>")

        // Then
        XCTAssertEqual(summary, #"Walter & Jesse's "business" <3>"#)
    }

    func test_searchShows_summaryWithoutText_isNil() async throws {
        for html in [nil, "", "   ", "<p></p>", "<p> <br> </p>"] {
            let summary = try await mappedSummary(from: html)
            XCTAssertNil(summary, "Expected nil summary for \(String(describing: html))")
        }
    }
}

// MARK: - Helpers

private extension TVSearchRepositoryTests {
    func mappedSummary(from html: String?) async throws -> String? {
        let remote = TVSearchRemoteMock(result: .success([.stub(id: 169, name: "Breaking Bad", summary: html)]))
        let repository = TVSearchRepository(remote: remote, cache: TVSearchCache())
        return try await repository.searchShows(for: Constants.query).first?.summary
    }
}

// MARK: - Stubs

private extension TVShowSearchResultDTO {
    static func stub(id: Int,
                     name: String,
                     summary: String? = "<p><b>Breaking Bad</b> follows a chemistry teacher.</p>",
                     network: String? = "AMC",
                     webChannel: String? = nil,
                     rating: Double? = 9.2,
                     image: TVImageDTO? = TVImageDTO(medium: URL(string: "https://static.tvmaze.com/medium.jpg"),
                                                     original: URL(string: "https://static.tvmaze.com/original.jpg"))) -> TVShowSearchResultDTO {
        TVShowSearchResultDTO(show: TVShowDTO(id: id,
                                              name: name,
                                              genres: ["Drama", "Crime"],
                                              premiered: "2008-01-20",
                                              ended: "2013-09-29",
                                              summary: summary,
                                              rating: TVRatingDTO(average: rating),
                                              image: image,
                                              network: network.map(TVNetworkDTO.init(name:)),
                                              webChannel: webChannel.map(TVNetworkDTO.init(name:))))
    }
}
