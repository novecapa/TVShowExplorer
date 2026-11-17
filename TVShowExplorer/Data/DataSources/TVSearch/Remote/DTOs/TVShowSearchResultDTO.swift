//
//  TVShowSearchResultDTO.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

struct TVShowSearchResultDTO: Decodable, Sendable {
    let score: Double
    let show: TVShowDTO
}
