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

// MARK: - Mock values

#if DEBUG

extension TVShow {
    static let mock = TVShow(id: 169,
                             name: "Breaking Bad",
                             type: "Scripted",
                             language: "English",
                             genres: ["Drama", "Crime", "Thriller"],
                             status: "Ended",
                             premiered: "2008-01-20",
                             ended: "2013-09-29",
                             summary: "Breaking Bad follows protagonist Walter White, a chemistry teacher who lives in New Mexico.",
                             rating: 9.2,
                             mediumImageURL: URL(string: "https://static.tvmaze.com/uploads/images/medium_portrait/501/1253519.jpg"),
                             originalImageURL: URL(string: "https://static.tvmaze.com/uploads/images/original_untouched/501/1253519.jpg"),
                             runtime: 60,
                             channel: "AMC",
                             officialSite: URL(string: "http://www.amc.com/shows/breaking-bad"))
}

#endif
