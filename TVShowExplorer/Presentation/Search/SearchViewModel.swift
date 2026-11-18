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
    @ObservationIgnored private var searchID = 0

    @ObservationIgnored private let useCase: TVSearchUseCaseProtocol
    @ObservationIgnored private let debounce: Duration

    init(useCase: TVSearchUseCaseProtocol,
         debounce: Duration = .milliseconds(300)) {
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
        searchID += 1

        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            searchTask = nil
            state = .idle
            return
        }

        state = .loading
        let id = searchID
        searchTask = Task {
            await performSearch(text, id: id)
        }
    }

    func performSearch(_ text: String, id: Int) async {
        do {
            try await Task.sleep(for: debounce)
            let shows = try await useCase.searchShows(for: text)
            guard id == searchID else { return }
            state = shows.isEmpty ? .empty : .loaded(shows)
        } catch {
            guard id == searchID else { return }
            state = .error
        }
    }
}
