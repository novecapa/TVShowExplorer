//
//  TVShow+Formatting.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 19/11/2026.
//

import Foundation

extension TVShow {

    var formattedGenres: String? {
        genres.isEmpty ? nil : genres.joined(separator: " · ")
    }

    var premiereYear: String? {
        guard let year = premiered?.prefix(4), !year.isEmpty else { return nil }
        return String(year)
    }

    var yearsOnAir: String? {
        guard let start = premiereYear else { return nil }
        guard let end = ended?.prefix(4), !end.isEmpty, end != start else { return start }
        return "\(start)–\(end)"
    }

    func formattedRating(locale: Locale = .autoupdatingCurrent) -> String? {
        rating?.formatted(.number.precision(.fractionLength(1)).locale(locale))
    }
}
