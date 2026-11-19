//
//  TVShowFormattingTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 19/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class TVShowFormattingTests: XCTestCase {

    enum Constants {
        static let locale = Locale(identifier: "en_US")
    }

    func test_formattedGenres_joinsGenresWithMiddleDot() {
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", genres: ["Drama", "Adventure"]).formattedGenres, "Drama · Adventure")
    }

    func test_formattedGenres_whenEmpty_isNil() {
        XCTAssertNil(TVShow.stub(id: 1, name: "Lost", genres: []).formattedGenres)
    }

    func test_formattedRating_hasOneDecimalInTheGivenLocale() {
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", rating: 8).formattedRating(locale: Constants.locale), "8.0")
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", rating: 9.2).formattedRating(locale: Locale(identifier: "es_ES")), "9,2")
    }

    func test_formattedRating_whenMissing_isNilInsteadOfZero() {
        XCTAssertNil(TVShow.stub(id: 1, name: "Lost", rating: nil).formattedRating(locale: Constants.locale))
    }

    func test_premiereYear_isTheYearOfThePremiereDate() {
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", premiered: "2004-09-22").premiereYear, "2004")
        XCTAssertNil(TVShow.stub(id: 1, name: "Lost", premiered: "").premiereYear)
        XCTAssertNil(TVShow.stub(id: 1, name: "Lost").premiereYear)
    }

    func test_yearsOnAir_withPartialOrMissingDates() {
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", premiered: "2004-09-22", ended: "2010-05-23").yearsOnAir, "2004–2010")
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", premiered: "2004-09-22").yearsOnAir, "2004")
        XCTAssertEqual(TVShow.stub(id: 1, name: "Lost", premiered: "2004-01-01", ended: "2004-12-01").yearsOnAir, "2004")
        XCTAssertNil(TVShow.stub(id: 1, name: "Lost", ended: "2010-05-23").yearsOnAir)
    }
}
