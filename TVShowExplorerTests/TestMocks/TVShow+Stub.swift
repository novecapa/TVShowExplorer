//
//  TVShow+Stub.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation
@testable import TVShowExplorer

extension TVShow {
    static func stub(id: Int,
                     name: String,
                     genres: [String] = [],
                     premiered: String? = nil,
                     ended: String? = nil,
                     summary: String? = nil,
                     rating: Double? = nil,
                     mediumImageURL: URL? = nil,
                     originalImageURL: URL? = nil,
                     channel: String? = nil) -> TVShow {
        TVShow(id: id,
               name: name,
               genres: genres,
               premiered: premiered,
               ended: ended,
               summary: summary,
               rating: rating,
               mediumImageURL: mediumImageURL,
               originalImageURL: originalImageURL,
               channel: channel)
    }
}
