//
//  TVSearchRemote.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

// MARK: - TVSearchRemoteProtocol

protocol TVSearchRemoteProtocol: Sendable {
    func searchShows(for query: String) async throws -> [TVShowSearchResultDTO]
}

// MARK: - TVSearchRemote

final class TVSearchRemote: TVSearchRemoteProtocol {

    private enum Endpoints {

        private static let baseURL = "https://api.tvmaze.com/"

        case searchShows

        var rawValue: String {
            switch self {
            case .searchShows:
                Endpoints.baseURL + "search/shows"
            }
        }
    }

    private enum Constants {
        static let query = "q"
    }

    private let networkClient: NetworkClientProtocol

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    func searchShows(for query: String) async throws -> [TVShowSearchResultDTO] {
        try await networkClient.call(urlString: Endpoints.searchShows.rawValue,
                                     method: .get,
                                     queryItems: [URLQueryItem(name: Constants.query,
                                                               value: query)],
                                     of: [TVShowSearchResultDTO].self)
    }
}
