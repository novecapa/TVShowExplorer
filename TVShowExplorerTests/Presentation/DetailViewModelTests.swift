//
//  DetailViewModelTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import XCTest
@testable import TVShowExplorer

@MainActor
final class DetailViewModelTests: XCTestCase {

    enum Constants {
        static let locale = Locale(identifier: "en_US")
        static let mediumImageURL = URL(string: "https://static.tvmaze.com/medium.jpg")
        static let originalImageURL = URL(string: "https://static.tvmaze.com/original.jpg")
    }

    func test_init_withSelectedShow_preparesItsData() {
        // Given
        let show = TVShow.stub(id: 169,
                               name: "Breaking Bad",
                               genres: ["Drama", "Crime", "Thriller"],
                               premiered: "2008-01-20",
                               ended: "2013-09-29",
                               summary: "A chemistry teacher.\nHis life changes.",
                               rating: 9.2,
                               mediumImageURL: Constants.mediumImageURL,
                               originalImageURL: Constants.originalImageURL,
                               channel: "AMC")

        // When
        let viewModel = makeViewModel(show: show)

        // Then
        XCTAssertEqual(viewModel.title, "Breaking Bad")
        XCTAssertEqual(viewModel.imageURL, Constants.originalImageURL)
        XCTAssertEqual(viewModel.genres, "Drama · Crime · Thriller")
        XCTAssertEqual(viewModel.rating, "9.2")
        XCTAssertEqual(viewModel.metadata, "2008–2013 · AMC")
        XCTAssertEqual(viewModel.summary, "A chemistry teacher.\nHis life changes.")
    }

    func test_imageURL_withoutOriginal_fallsBackToMediumOrNil() {
        XCTAssertEqual(makeViewModel(show: .stub(id: 1, name: "Lost", mediumImageURL: Constants.mediumImageURL)).imageURL,
                       Constants.mediumImageURL)
        XCTAssertNil(makeViewModel(show: .stub(id: 1, name: "Lost")).imageURL)
    }

    func test_metadata_withPartialOrMissingData() {
        XCTAssertEqual(makeViewModel(show: .stub(id: 1, name: "Lost", premiered: "2004-09-22")).metadata, "2004")
        XCTAssertEqual(makeViewModel(show: .stub(id: 1, name: "Lost", channel: "ABC")).metadata, "ABC")
        XCTAssertNil(makeViewModel(show: .stub(id: 1, name: "Lost")).metadata)
    }
}

// MARK: - Helpers

private extension DetailViewModelTests {

    func makeViewModel(show: TVShow) -> DetailViewModel {
        DetailViewModel(show: show, locale: Constants.locale)
    }
}
