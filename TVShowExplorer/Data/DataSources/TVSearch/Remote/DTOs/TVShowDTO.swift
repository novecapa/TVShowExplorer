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
    let type: String?
    let language: String?
    let genres: [String]
    let status: String?
    let runtime: Int?
    let averageRuntime: Int?
    let premiered: String?
    let ended: String?
    let officialSite: String?
    let summary: String?

    let rating: TVRatingDTO?
    let image: TVImageDTO?
    let schedule: TVScheduleDTO?
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

struct TVScheduleDTO: Decodable, Sendable {
    let time: String
    let days: [String]
}
