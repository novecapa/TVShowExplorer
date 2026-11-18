//
//  TVShowDTO.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

struct TVShowDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let genres: [String]
    let premiered: String?
    let ended: String?
    let summary: String?

    let rating: TVRatingDTO?
    let image: TVImageDTO?
    let network: TVNetworkDTO?
    let webChannel: TVNetworkDTO?
}

struct TVImageDTO: Decodable, Sendable {
    let medium: URL?
    let original: URL?
}

struct TVNetworkDTO: Decodable, Sendable {
    let name: String
}

struct TVRatingDTO: Decodable, Sendable {
    let average: Double?
}
