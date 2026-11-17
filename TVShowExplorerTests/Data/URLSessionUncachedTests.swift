//
//  URLSessionUncachedTests.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import XCTest
@testable import TVShowExplorer

final class URLSessionUncachedTests: XCTestCase {

    func test_uncached_disablesHTTPCache() {
        // When
        let configuration = URLSession.uncached.configuration

        // Then
        XCTAssertNil(configuration.urlCache)
        XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }
}
