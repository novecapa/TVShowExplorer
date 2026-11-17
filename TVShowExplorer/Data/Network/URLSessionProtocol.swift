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
