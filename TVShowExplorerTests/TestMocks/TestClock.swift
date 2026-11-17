//
//  TestClock.swift
//  TVShowExplorerTests
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import Foundation
import Synchronization

final class TestClock: Sendable {

    private let current = Mutex(Date(timeIntervalSinceReferenceDate: 0))

    var now: Date {
        current.withLock { $0 }
    }

    func advance(by seconds: TimeInterval) {
        current.withLock { $0 += seconds }
    }
}
