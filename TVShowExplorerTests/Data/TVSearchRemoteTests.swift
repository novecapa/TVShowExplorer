//
//  TVSearchRemoteTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class TVSearchRemoteTests: XCTestCase {

    func test_searchShows_requestsTVMazeSearchEndpointWithQuery() async throws {
        // Given
        let session = try URLSessionMock.responding(statusCode: 200, body: "[]")
        let remote = TVSearchRemote(networkClient: NetworkClient(urlSession: session))

        // When
        _ = try await remote.searchShows(for: "breaking bad")

        // Then
        let requests = await session.receivedRequests
        XCTAssertEqual(requests.map(\.url?.absoluteString), ["https://api.tvmaze.com/search/shows?q=breaking%20bad"])
        XCTAssertEqual(requests.first?.httpMethod, "GET")
    }

    func test_searchShows_decodesTVMazePayloadIncludingNullFields() async throws {
        // Given
        let session = try URLSessionMock.responding(statusCode: 200, body: Fixtures.searchResponse)
        let remote = TVSearchRemote(networkClient: NetworkClient(urlSession: session))

        // When
        let results = try await remote.searchShows(for: "breaking")

        // Then
        XCTAssertEqual(results.map(\.show.id), [169, 1])
        let complete = try XCTUnwrap(results.first?.show)
        XCTAssertEqual(complete.name, "Breaking Bad")
        XCTAssertEqual(complete.genres, ["Drama", "Crime", "Thriller"])
        XCTAssertEqual(complete.rating?.average, 9.2)
        XCTAssertEqual(complete.image?.original?.absoluteString,
                       "https://static.tvmaze.com/uploads/images/original_untouched/501/1253519.jpg")
        XCTAssertEqual(complete.network?.name, "AMC")
        XCTAssertEqual(complete.summary, "<p><b>Breaking Bad</b> follows a chemistry teacher.</p>")

        let partial = try XCTUnwrap(results.last?.show)
        XCTAssertNil(partial.network)
        XCTAssertEqual(partial.webChannel?.name, "Netflix")
        XCTAssertNil(partial.rating?.average)
        XCTAssertNil(partial.image)
        XCTAssertNil(partial.premiered)
        XCTAssertNil(partial.summary)
    }
}

// MARK: - Fixtures

private enum Fixtures {

    /// Trimmed `/search/shows` response, including keys the DTOs ignore.
    /// The first show is complete, the second has the nullable fields set to null.
    static let searchResponse = """
    [
      {
        "score": 0.91,
        "show": {
          "id": 169,
          "url": "https://www.tvmaze.com/shows/169/breaking-bad",
          "name": "Breaking Bad",
          "type": "Scripted",
          "language": "English",
          "genres": ["Drama", "Crime", "Thriller"],
          "status": "Ended",
          "runtime": 60,
          "averageRuntime": 60,
          "premiered": "2008-01-20",
          "ended": "2019-10-11",
          "officialSite": "http://www.amc.com/shows/breaking-bad",
          "schedule": { "time": "22:00", "days": ["Sunday"] },
          "rating": { "average": 9.2 },
          "weight": 100,
          "network": {
            "id": 20,
            "name": "AMC",
            "country": { "name": "United States", "code": "US", "timezone": "America/New_York" },
            "officialSite": null
          },
          "webChannel": null,
          "externals": { "tvrage": 18164, "thetvdb": 81189, "imdb": "tt0903747" },
          "image": {
            "medium": "https://static.tvmaze.com/uploads/images/medium_portrait/501/1253519.jpg",
            "original": "https://static.tvmaze.com/uploads/images/original_untouched/501/1253519.jpg"
          },
          "summary": "<p><b>Breaking Bad</b> follows a chemistry teacher.</p>",
          "updated": 1792795009
        }
      },
      {
        "score": 0.52,
        "show": {
          "id": 1,
          "name": "Breaking Point",
          "type": "Documentary",
          "language": null,
          "genres": [],
          "status": "In Development",
          "runtime": null,
          "averageRuntime": 45,
          "premiered": null,
          "ended": null,
          "officialSite": null,
          "schedule": { "time": "", "days": [] },
          "rating": { "average": null },
          "network": null,
          "webChannel": { "id": 1, "name": "Netflix", "country": null },
          "image": null,
          "summary": null
        }
      }
    ]
    """
}
