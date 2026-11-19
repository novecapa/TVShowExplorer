//
//  SearchView.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import SwiftUI

struct SearchView: View {

    private enum Constants {
        static let chipSpacing: CGFloat = 8
        static let chipsVerticalPadding: CGFloat = 8
    }

    @State private var viewModel: SearchViewModel
    @State private var path: [TVShow] = []

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !viewModel.recentSearches.isEmpty {
                    recentSearches
                }
                results
            }
            .listStyle(.plain)
            .overlay {
                stateOverlay
            }
            .navigationTitle("TV Shows")
            .searchable(text: $viewModel.query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search by show name")
            .navigationDestination(for: TVShow.self) { show in
                DetailViewBuilder().build(show: show)
            }
        }
        .onChange(of: path) { oldPath, newPath in
            if newPath.count > oldPath.count {
                viewModel.recordSelectedSearch()
            }
        }
    }

    private var recentSearches: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Constants.chipSpacing) {
                ForEach(viewModel.recentSearches, id: \.self) { recentSearch in
                    Button(recentSearch) {
                        viewModel.query = recentSearch
                    }
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .padding(.horizontal)
            .padding(.vertical, Constants.chipsVerticalPadding)
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var results: some View {
        if case .loaded(let shows) = viewModel.state {
            ForEach(shows) { show in
                NavigationLink(value: show) {
                    TVShowCellView(show: show)
                }
            }
        }
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search TV Shows",
                                   systemImage: "tv",
                                   description: Text("Type the name of a show to start."))
        case .loading:
            ProgressView()
        case .loaded:
            EmptyView()
        case .empty:
            ContentUnavailableView.search(text: viewModel.query)
        case .error:
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text("We couldn't load the shows. Please try again.")
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
