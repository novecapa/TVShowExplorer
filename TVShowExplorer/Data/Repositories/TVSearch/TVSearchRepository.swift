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

    init(remote: TVSearchRemoteProtocol) {
        self.remote = remote
    }

    func searchShows(for query: String) async throws -> [TVShow] {
        try await remote.searchShows(for: query).map { $0.show.toEntity }
    }
}

// MARK: - TVShowDTO

private extension TVShowDTO {
    var toEntity: TVShow {
        TVShow(id: id,
               name: name,
               type: type,
               language: language,
               genres: genres,
               status: status,
               premiered: premiered,
               ended: ended,
               summary: summary?.htmlToPlainText,
               rating: rating?.average,
               mediumImageURL: image?.medium,
               originalImageURL: image?.original,
               runtime: runtime ?? averageRuntime,
               channel: network?.name ?? webChannel?.name,
               officialSite: officialSite.flatMap { URL(string: $0) })
    }
}

// MARK: - HTML summary

private extension String {
    var htmlToPlainText: String? {
        let text = self
            .replacing(/<\/p>|<br\s*\/?>/.ignoresCase(), with: "\n")
            .replacing(/<[^>]+>/, with: "")
            .replacing("&quot;", with: "\"")
            .replacing("&#39;", with: "'")
            .replacing("&lt;", with: "<")
            .replacing("&gt;", with: ">")
            .replacing("&nbsp;", with: " ")
            .replacing("&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
