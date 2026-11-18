//
//  NetworkClientTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class NetworkClientTests: XCTestCase {

    enum Constants {
        static let urlString = "https://api.tvmaze.com/search/shows"
        static let validBody = #"{"id": 169, "name": "Breaking Bad"}"#
    }

    // MARK: - Request

    func test_call_sendsGETRequestWithPercentEncodedQueryItems() async throws {
        // Given
        let session = try URLSessionMock.responding(statusCode: 200, body: Constants.validBody)

        // When
        _ = try await call(session, queryItems: [URLQueryItem(name: "q", value: "c++ & co")])

        // Then
        let requests = await session.receivedRequests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.url?.absoluteString, "https://api.tvmaze.com/search/shows?q=c%2B%2B%20%26%20co")
        XCTAssertEqual(requests.first?.httpMethod, "GET")
    }

    func test_call_withInvalidURL_throwsBadURLWithoutSendingRequest() async throws {
        // Given
        let session = try URLSessionMock.responding(statusCode: 200, body: Constants.validBody)

        // When
        do {
            _ = try await call(session, urlString: "https://api.tv maze.com")
            XCTFail("Expected NetworkError.badURL")
        } catch {
            XCTAssertEqual(error as? NetworkError, .badURL)
        }

        // Then
        let requests = await session.receivedRequests
        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: - HTTP status codes

    func test_call_withHTTP200_decodesResponseBody() async throws {
        // Given
        let session = try URLSessionMock.responding(statusCode: 200, body: Constants.validBody)

        // When
        let show = try await call(session)

        // Then
        XCTAssertEqual(show, ShowStub(id: 169, name: "Breaking Bad"))
    }

    func test_call_withHTTP404_throwsNotFound() async throws {
        await assertCall(with: try .responding(statusCode: 404, body: Constants.validBody), throws: .notFound)
    }

    func test_call_withHTTP429_throwsRateLimited() async throws {
        await assertCall(with: try .responding(statusCode: 429, body: Constants.validBody), throws: .rateLimited)
    }

    func test_call_withOtherClientErrors_throwsBadRequest() async throws {
        for statusCode in [400, 401, 403, 422] {
            await assertCall(with: try .responding(statusCode: statusCode, body: Constants.validBody),
                             throws: .badRequest,
                             "HTTP \(statusCode)")
        }
    }

    func test_call_withServerErrors_throwsServerError() async throws {
        for statusCode in [500, 502, 503] {
            await assertCall(with: try .responding(statusCode: statusCode, body: Constants.validBody),
                             throws: .serverError,
                             "HTTP \(statusCode)")
        }
    }

    func test_call_withStatusOutsideHandledRanges_throwsBadResponse() async throws {
        await assertCall(with: try .responding(statusCode: 304, body: Constants.validBody), throws: .badResponse)
    }

    // MARK: - Transport and payload errors

    func test_call_withTransportError_throwsConnectivity() async {
        for code in [URLError.notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost] {
            await assertCall(with: URLSessionMock(result: .failure(URLError(code))),
                             throws: .connectivity,
                             "URLError \(code.rawValue)")
        }
    }

    func test_call_withNonHTTPResponse_throwsBadResponse() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: Constants.urlString))
        let response = URLResponse(url: url, mimeType: "application/json", expectedContentLength: 0, textEncodingName: nil)
        let session = URLSessionMock(result: .success((Data(Constants.validBody.utf8), response)))

        // When / Then
        await assertCall(with: session, throws: .badResponse)
    }

    func test_call_withMalformedOrUnexpectedJSON_throwsDecodeError() async throws {
        for body in ["", "{", #"{"id": "169", "name": "Breaking Bad"}"#, #"[{"id": 169, "name": "Breaking Bad"}]"#] {
            await assertCall(with: try .responding(statusCode: 200, body: body), throws: .decodeError, body)
        }
    }

    // MARK: - Cancellation

    func test_call_whenSessionReportsCancellation_throwsCancellationErrorInsteadOfConnectivity() async throws {
        // Given: URLSession reports a cancelled task as URLError.cancelled
        let session = URLSessionMock(result: .failure(URLError(.cancelled)))

        // When / Then
        do {
            _ = try await call(session)
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_call_cancelledWhileRequestIsInFlight_discardsValidResponse() async throws {
        // Given: the task is cancelled while waiting and the session still returns a valid response
        let session = try URLSessionMock.responding(statusCode: 200, body: Constants.validBody, cancelsCallingTask: true)

        // When / Then
        do {
            let show = try await call(session)
            XCTFail("Expected CancellationError, got \(show)")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Helpers

private extension NetworkClientTests {

    func call(_ session: URLSessionMock,
              urlString: String = Constants.urlString,
              queryItems: [URLQueryItem] = []) async throws -> ShowStub {
        try await NetworkClient(urlSession: session).call(urlString: urlString,
                                                          method: .get,
                                                          queryItems: queryItems,
                                                          of: ShowStub.self)
    }

    func assertCall(with session: URLSessionMock,
                    throws expectedError: NetworkError,
                    _ message: String = "",
                    file: StaticString = #filePath,
                    line: UInt = #line) async {
        do {
            let show = try await call(session)
            XCTFail("Expected \(expectedError), got \(show). \(message)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? NetworkError, expectedError, message, file: file, line: line)
        }
    }
}

// MARK: - Stubs

private struct ShowStub: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
}
