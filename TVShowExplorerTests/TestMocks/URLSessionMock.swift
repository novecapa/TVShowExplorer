//
//  URLSessionMock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import XCTest
@testable import TVShowExplorer

actor URLSessionMock: URLSessionProtocol {

    private(set) var receivedRequests: [URLRequest] = []
    private let result: Result<(Data, URLResponse), Error>
    private let cancelsCallingTask: Bool

    init(result: Result<(Data, URLResponse), Error>, cancelsCallingTask: Bool = false) {
        self.result = result
        self.cancelsCallingTask = cancelsCallingTask
    }

    static func responding(statusCode: Int,
                           body: String,
                           cancelsCallingTask: Bool = false) throws -> URLSessionMock {
        let url = try XCTUnwrap(URL(string: "https://api.tvmaze.com"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil))
        return URLSessionMock(result: .success((Data(body.utf8), response)), cancelsCallingTask: cancelsCallingTask)
    }

    func getDataFrom(_ request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequests.append(request)
        if cancelsCallingTask {
            withUnsafeCurrentTask { $0?.cancel() }
        }
        return try result.get()
    }
}
