//
//  TVSearchRepository.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

// MARK: - TVSearchRepository

final class TVSearchRepository: TVSearchRepositoryProtocol {

    private let remote: TVSearchRemoteProtocol
    private let cache: TVSearchCache

    init(remote: TVSearchRemoteProtocol, cache: TVSearchCache) {
        self.remote = remote
        self.cache = cache
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        let cachedShows = await cache.shows(for: query)
        try Task.checkCancellation()
        if let cachedShows {
            return cachedShows
        }

        let shows = try await remote.searchShows(for: query).map { $0.show.toEntity }
        try Task.checkCancellation()
        await cache.store(shows, for: query)
        return shows
    }
}

// MARK: - TVShowDTO

private extension TVShowDTO {
    var toEntity: TVShow {
        TVShow(id: id,
               name: name,
               genres: genres,
               premiered: premiered,
               ended: ended,
               summary: summary?.htmlToPlainText,
               rating: rating?.average,
               mediumImageURL: image?.medium,
               originalImageURL: image?.original,
               channel: network?.name ?? webChannel?.name)
    }
}

// MARK: - HTML summary

private extension String {
    var htmlToPlainText: String? {
        let text = self
            .replacing(/\s+/, with: " ")
            .replacing(/<\/p>|<br\s*\/?>/.ignoresCase(), with: "\n")
            .replacing(/<[^>]+>/, with: "")
            .replacing("&quot;", with: "\"")
            .replacing("&#39;", with: "'")
            .replacing("&apos;", with: "'")
            .replacing("&lt;", with: "<")
            .replacing("&gt;", with: ">")
            .replacing("&nbsp;", with: " ")
            .replacing("&amp;", with: "&")
        let paragraphs = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return paragraphs.isEmpty ? nil : paragraphs.joined(separator: "\n")
    }
}
