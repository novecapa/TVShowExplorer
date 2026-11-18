//
//  SearchViewBuilderMock.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

#if DEBUG

final class SearchViewBuilderMock {

    private enum Constants {
        static let query = "breaking"
    }

    @MainActor
    func build(state: SearchViewModel.State) -> SearchView {
        let useCase = TVSearchUseCasePreviewMock(state: state)
        let viewModel = SearchViewModel(useCase: useCase, debounce: .zero)
        if state != .idle {
            viewModel.query = Constants.query
        }
        return SearchView(viewModel: viewModel)
    }
}

// MARK: - TVSearchUseCasePreviewMock

private struct TVSearchUseCasePreviewMock: TVSearchUseCaseProtocol {

    let state: SearchViewModel.State

    func searchShows(for query: String) async throws -> [TVShow] {
        switch state {
        case .idle, .empty:
            return []
        case .loaded(let shows):
            return shows
        case .error:
            throw NetworkError.connectivity
        case .loading:
            try await Task.sleep(for: .seconds(3600))
            return []
        }
    }
}

#endif
