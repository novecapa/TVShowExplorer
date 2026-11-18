//
//  SearchViewBuilder.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import Foundation

final class SearchViewBuilder {

    private static let cache = TVSearchCache()

    @MainActor
    func build() -> SearchView {
        let networkClient = NetworkClient(urlSession: URLSession.uncached)
        let remote = TVSearchRemote(networkClient: networkClient)
        let repository = TVSearchRepository(remote: remote, cache: Self.cache)
        let useCase = TVSearchUseCase(repository: repository)
        let viewModel = SearchViewModel(useCase: useCase)
        return SearchView(viewModel: viewModel)
    }
}
