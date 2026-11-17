//
//  NetworkClient.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

enum NetworkMethod: String {
    case get
}

protocol NetworkClientProtocol: Sendable {
    func call<T: Decodable & Sendable>(urlString: String,
                                       method: NetworkMethod,
                                       queryItems: [URLQueryItem],
                                       of type: T.Type) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {

    private let urlSession: any URLSessionProtocol
    private let decoder: JSONDecoder

    init(urlSession: any URLSessionProtocol,
         decoder: JSONDecoder = JSONDecoder()) {
        self.urlSession = urlSession
        self.decoder = decoder
    }

    @concurrent
    func call<T: Decodable & Sendable>(urlString: String,
                                       method: NetworkMethod,
                                       queryItems: [URLQueryItem],
                                       of type: T.Type) async throws -> T {

        guard var urlComponents = URLComponents(string: urlString) else {
            throw NetworkError.badURL
        }
        if !queryItems.isEmpty {
            urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
            urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = urlComponents.url else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue.uppercased()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.getDataFrom(request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is URLError {
            throw NetworkError.connectivity
        }
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.badResponse
        }

        Log.thisRequest(response, data: data, request: request)

        switch response.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodeError
            }
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 400..<500:
            throw NetworkError.badRequest
        case 500..<600:
            throw NetworkError.serverError
        default:
            throw NetworkError.badResponse
        }
    }
}
