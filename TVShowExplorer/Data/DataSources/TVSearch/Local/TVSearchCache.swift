//
//  TVSearchCache.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation

// MARK: - TVSearchCache

actor TVSearchCache {

    private enum Constants {
        static let defaultTimeToLive: TimeInterval = 180
    }

    private struct Entry {
        let shows: [TVShow]
        let expirationDate: Date
    }

    private let timeToLive: TimeInterval
    private let now: @Sendable () -> Date
    private var entries: [String: Entry] = [:]

    init(timeToLive: TimeInterval = Constants.defaultTimeToLive,
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.timeToLive = timeToLive
        self.now = now
    }

    func shows(for query: String) -> [TVShow]? {
        let key = Self.key(for: query)
        guard let entry = entries[key] else { return nil }
        guard now() < entry.expirationDate else {
            entries[key] = nil
            return nil
        }
        return entry.shows
    }

    func store(_ shows: [TVShow], for query: String) {
        entries[Self.key(for: query)] = Entry(shows: shows,
                                              expirationDate: now().addingTimeInterval(timeToLive))
    }

    private static func key(for query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
