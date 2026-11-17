//
//  TVShow.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

struct TVShow: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let type: String?
    let language: String?
    let genres: [String]
    let status: String?
    let premiered: String?
    let ended: String?
    let summary: String?
    let rating: Double?
    let mediumImageURL: URL?
    let originalImageURL: URL?
    let runtime: Int?
    let channel: String?
    let officialSite: URL?
}
