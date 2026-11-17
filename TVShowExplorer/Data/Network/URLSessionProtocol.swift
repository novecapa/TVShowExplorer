//
//  URLSessionProtocol.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

protocol URLSessionProtocol: Sendable {
    func getDataFrom(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    func getDataFrom(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

// MARK: - Uncached session (TVMaze API)

extension URLSession {
    static let uncached = URLSession(configuration: .uncached)
}

private extension URLSessionConfiguration {
    static var uncached: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return configuration
    }
}
