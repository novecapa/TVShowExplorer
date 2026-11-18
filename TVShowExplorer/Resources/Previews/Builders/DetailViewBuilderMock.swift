//
//  DetailViewBuilderMock.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation

#if DEBUG

final class DetailViewBuilderMock {

    @MainActor
    func build(show: TVShow = .mock) -> DetailView {
        let viewModel = DetailViewModel(show: show)
        return DetailView(viewModel: viewModel)
    }
}

// MARK: - TVShow preview mocks

extension TVShow {

    static let mockWithoutImage = makeMock(mediumImageURL: nil, originalImageURL: nil)

    static let mockWithoutRatingAndGenres = makeMock(genres: [], rating: nil)

    static let mockWithoutSummary = makeMock(summary: nil)

    static let mockLongContent = makeMock(
        name: "The Extraordinarily Long and Winding Chronicles of a Chemistry Teacher in New Mexico",
        genres: ["Drama", "Crime", "Thriller", "Science-Fiction", "Mystery", "Supernatural", "Family"],
        summary: """
        Breaking Bad follows protagonist Walter White, a chemistry teacher who lives in New Mexico \
        with his wife and teenage son who has cerebral palsy. White is diagnosed with Stage III cancer and \
        given a prognosis of two years left to live.
        With a new sense of fearlessness based on his medical prognosis, and a desire to secure his \
        family's financial security, White chooses to enter a dangerous world of drugs and crime and \
        ascends to power in this world.
        The series explores how a fatal diagnosis such as White's releases a typical man from the \
        daily concerns and constraints of normal society and follows his transformation from \
        mild family man to a kingpin of the drug trade.
        """
    )
}

private extension TVShow {

    static func makeMock(name: String = mock.name,
                         genres: [String] = mock.genres,
                         summary: String? = mock.summary,
                         rating: Double? = mock.rating,
                         mediumImageURL: URL? = mock.mediumImageURL,
                         originalImageURL: URL? = mock.originalImageURL) -> TVShow {
        TVShow(id: mock.id,
               name: name,
               genres: genres,
               premiered: mock.premiered,
               ended: mock.ended,
               summary: summary,
               rating: rating,
               mediumImageURL: mediumImageURL,
               originalImageURL: originalImageURL,
               channel: mock.channel)
    }
}

#endif
