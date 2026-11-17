//
//  NetworkError.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

enum NetworkError: Error, Hashable {
    case badResponse
    case badRequest
    case notFound
    case rateLimited
    case serverError
    case badURL
    case decodeError
    case connectivity
}
