//
//  SearchView.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import SwiftUI

struct SearchView: View {

    @State private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("TV Shows")
                .searchable(text: $viewModel.query,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search by show name")
                .navigationDestination(for: TVShow.self) { show in
                    DetailView(show: show)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search TV Shows",
                                   systemImage: "tv",
                                   description: Text("Type the name of a show to start."))
        case .loading:
            ProgressView()
        case .loaded(let shows):
            List(shows) { show in
                NavigationLink(value: show) {
                    TVShowCellView(show: show)
                }
            }
            .listStyle(.plain)
        case .empty:
            ContentUnavailableView.search(text: viewModel.query)
        case .error:
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text("We couldn't load the shows. Check your connection and try again.")
            } actions: {
                Button("Retry") {
                    viewModel.retry()
                }
            }
        }
    }
}

#if DEBUG

#Preview("Idle") {
    SearchViewBuilderMock().build(state: .idle)
}

#Preview("Loading") {
    SearchViewBuilderMock().build(state: .loading)
}

#Preview("Loaded") {
    SearchViewBuilderMock().build(state: .loaded([.mock]))
}

#Preview("Empty") {
    SearchViewBuilderMock().build(state: .empty)
}

#Preview("Error") {
    SearchViewBuilderMock().build(state: .error)
}

#endif
