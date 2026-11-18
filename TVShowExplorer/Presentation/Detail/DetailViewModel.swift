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
        genres = show.genres.isEmpty ? nil : show.genres.joined(separator: " · ")
        rating = show.rating.map { $0.formatted(.number.precision(.fractionLength(1)).locale(locale)) }
        metadata = Self.metadata(for: show)
        summary = show.summary
    }
}

// MARK: - Metadata

private extension DetailViewModel {

    static func metadata(for show: TVShow) -> String? {
        let items = [years(premiered: show.premiered, ended: show.ended), show.channel].compactMap { $0 }
        return items.isEmpty ? nil : items.joined(separator: " · ")
    }

    static func years(premiered: String?, ended: String?) -> String? {
        guard let start = premiered?.prefix(4), !start.isEmpty else { return nil }
        guard let end = ended?.prefix(4), !end.isEmpty, end != start else { return String(start) }
        return "\(start)–\(end)"
    }
}
