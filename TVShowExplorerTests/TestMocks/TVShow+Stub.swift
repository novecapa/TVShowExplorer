//
//  TVShow+Stub.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation
@testable import TVShowExplorer

extension TVShow {
    static func stub(id: Int, name: String) -> TVShow {
        TVShow(id: id,
               name: name,
               type: nil,
               language: nil,
               genres: [],
               status: nil,
               premiered: nil,
               ended: nil,
               summary: nil,
               rating: nil,
               mediumImageURL: nil,
               originalImageURL: nil,
               runtime: nil,
               channel: nil,
               officialSite: nil)
    }
}
