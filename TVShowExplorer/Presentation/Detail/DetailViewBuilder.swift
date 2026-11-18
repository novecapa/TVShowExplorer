//
//  DetailViewBuilder.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

final class DetailViewBuilder {

    @MainActor
    func build(show: TVShow) -> DetailView {
        let viewModel = DetailViewModel(show: show)
        return DetailView(viewModel: viewModel)
    }
}
