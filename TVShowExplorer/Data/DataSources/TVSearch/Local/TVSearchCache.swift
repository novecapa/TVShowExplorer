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
        let currentDate = now()
        guard currentDate < entry.expirationDate else {
            entries[key] = nil
            return nil
        }
        logCacheHit(entry, key: key, at: currentDate)
        return entry.shows
    }

    func store(_ shows: [TVShow], for query: String) {
        entries[Self.key(for: query)] = Entry(shows: shows,
                                              expirationDate: now().addingTimeInterval(timeToLive))
    }

    private static func key(for query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func logCacheHit(_ entry: Entry, key: String, at date: Date) {
        #if DEBUG
        let expiresIn = Int(entry.expirationDate.timeIntervalSince(date))
        print("------------------------------------------")
        print("💾 CACHE ✅ [HIT] \"\(key)\"")
        print("   \(entry.shows.count) shows · expires in \(expiresIn)s")
        print("------------------------------------------")
        #endif
    }
}
