//
//  DetailViewModel.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation

@MainActor
final class DetailViewModel {

    let title: String
    let imageURL: URL?
    let genres: String?
    let rating: String?
    let metadata: String?
    let summary: String?

    init(show: TVShow, locale: Locale = .autoupdatingCurrent) {
        title = show.name
        imageURL = show.originalImageURL ?? show.mediumImageURL
        genres = show.formattedGenres
        rating = show.formattedRating(locale: locale)
        metadata = Self.metadata(for: show)
        summary = show.summary
    }
}

// MARK: - Metadata

private extension DetailViewModel {

    static func metadata(for show: TVShow) -> String? {
        let items = [show.yearsOnAir, show.channel].compactMap { $0 }
        return items.isEmpty ? nil : items.joined(separator: " · ")
    }
}
