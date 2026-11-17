//
//  TVSearchCacheTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class TVSearchCacheTests: XCTestCase {

    enum Constants {
        static let query = "breaking"
        static let otherQuery = "lost"
    }

    var clock: TestClock!
    var cache: TVSearchCache!

    override func setUp() {
        super.setUp()
        let clock = TestClock()
        self.clock = clock
        self.cache = TVSearchCache(now: { clock.now })
    }

    override func tearDown() {
        clock = nil
        cache = nil
        super.tearDown()
    }

    func test_shows_whenKeyDoesNotExist_returnsNil() async {
        // When
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertNil(shows)
    }

    func test_store_thenShows_returnsStoredShows() async {
        // Given
        let stored = [TVShow.stub(id: 1, name: "Breaking Bad"), TVShow.stub(id: 2, name: "Breaking Point")]

        // When
        await cache.store(stored, for: Constants.query)
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertEqual(shows, stored)
    }

    func test_shows_after179Seconds_isStillValid() async {
        // Given
        await cache.store([.stub(id: 1, name: "Breaking Bad")], for: Constants.query)

        // When
        clock.advance(by: 179)
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertNotNil(shows)
    }

    func test_shows_afterExactly180Seconds_isExpired() async {
        // Given
        await cache.store([.stub(id: 1, name: "Breaking Bad")], for: Constants.query)

        // When
        clock.advance(by: 180)
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertNil(shows)
    }

    func test_shows_after181Seconds_isExpired() async {
        // Given
        await cache.store([.stub(id: 1, name: "Breaking Bad")], for: Constants.query)

        // When
        clock.advance(by: 181)
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertNil(shows)
    }

    func test_shows_readingDoesNotRestartTTL() async {
        // Given
        await cache.store([.stub(id: 1, name: "Breaking Bad")], for: Constants.query)

        // When
        clock.advance(by: 60)
        let readAt60 = await cache.shows(for: Constants.query)
        clock.advance(by: 119)
        let readAt179 = await cache.shows(for: Constants.query)
        clock.advance(by: 1)
        let readAt180 = await cache.shows(for: Constants.query)

        // Then
        XCTAssertNotNil(readAt60)
        XCTAssertNotNil(readAt179)
        XCTAssertNil(readAt180, "Reads must not extend the expiration date")
    }

    func test_store_newResponseRestartsTTL() async {
        // Given
        await cache.store([.stub(id: 1, name: "Breaking Bad")], for: Constants.query)
        clock.advance(by: 100)
        let replacement = [TVShow.stub(id: 2, name: "Breaking Point")]

        // When
        await cache.store(replacement, for: Constants.query)
        clock.advance(by: 179)
        let readAt279 = await cache.shows(for: Constants.query)
        clock.advance(by: 1)
        let readAt280 = await cache.shows(for: Constants.query)

        // Then
        XCTAssertEqual(readAt279, replacement)
        XCTAssertNil(readAt280)
    }

    func test_shows_normalizedQueriesShareEntry() async {
        // Given
        let stored = [TVShow.stub(id: 1, name: "Breaking Bad")]

        // When
        await cache.store(stored, for: "Breaking")

        // Then
        let lowercased = await cache.shows(for: "breaking")
        let padded = await cache.shows(for: " breaking ")
        let uppercased = await cache.shows(for: "BREAKING")
        XCTAssertEqual(lowercased, stored)
        XCTAssertEqual(padded, stored)
        XCTAssertEqual(uppercased, stored)
    }

    func test_shows_differentQueriesKeepIndependentEntries() async {
        // Given
        let breaking = [TVShow.stub(id: 1, name: "Breaking Bad")]
        let lost = [TVShow.stub(id: 2, name: "Lost")]
        await cache.store(breaking, for: Constants.query)
        clock.advance(by: 100)
        await cache.store(lost, for: Constants.otherQuery)

        // When
        let breakingAt100 = await cache.shows(for: Constants.query)
        let lostAt100 = await cache.shows(for: Constants.otherQuery)
        clock.advance(by: 80)
        let breakingAt180 = await cache.shows(for: Constants.query)
        let lostAt180 = await cache.shows(for: Constants.otherQuery)

        // Then
        XCTAssertEqual(breakingAt100, breaking)
        XCTAssertEqual(lostAt100, lost)
        XCTAssertNil(breakingAt180)
        XCTAssertEqual(lostAt180, lost)
    }

    func test_store_emptyResults_isCached() async {
        // When
        await cache.store([], for: Constants.query)
        let shows = await cache.shows(for: Constants.query)

        // Then
        XCTAssertEqual(shows, [], "An empty result is a cache hit, not a miss")
    }
}

// MARK: - Stubs

private extension TVShow {
    static func stub(id: Int, name: String) -> TVShow {
        TVShow(id: id,
               name: name,
               type: nil,
               language: nil,
               genres: [],
               status: nil,
               premiered: nil,
               ended: nil,
               summary: nil,
               rating: nil,
               mediumImageURL: nil,
               originalImageURL: nil,
               runtime: nil,
               channel: nil,
               officialSite: nil)
    }
}
