//
//  SearchViewModel.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {

    enum State: Equatable {
        case idle
        case loading
        case loaded([TVShow])
        case empty
        case error
    }

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            search()
        }
    }

    private(set) var state: State = .idle

    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?

    private let useCase: TVSearchUseCaseProtocol
    private let debounce: Duration

    init(useCase: TVSearchUseCaseProtocol,
         debounce: Duration = .milliseconds(800)) {
        self.useCase = useCase
        self.debounce = debounce
    }

    func retry() {
        search()
    }
}

// MARK: - Search

private extension SearchViewModel {

    func search() {
        searchTask?.cancel()

        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        searchTask = Task {
            await performSearch(text)
        }
    }

    func performSearch(_ text: String) async {
        do {
            try await Task.sleep(for: debounce)
            let shows = try await useCase.searchShows(for: text)
            guard !Task.isCancelled else { return }
            state = shows.isEmpty ? .empty : .loaded(shows)
        } catch {
            guard !Task.isCancelled else { return }
            state = .error
        }
    }
}
