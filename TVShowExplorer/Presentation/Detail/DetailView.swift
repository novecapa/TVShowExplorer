//
//  DetailView.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import SwiftUI

struct DetailView: View {

    private enum Constants {
        static let spacing: CGFloat = 20
        static let sectionSpacing: CGFloat = 8
        static let metadataSpacing: CGFloat = 12
        static let posterHeightRatio: CGFloat = 0.55
        static let posterAspectRatio: CGFloat = 0.68
        static let fallbackHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 12
    }

    private let viewModel: DetailViewModel

    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.spacing) {
                poster
                header
                summarySection
            }
            .padding()
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Poster

private extension DetailView {

    @ViewBuilder
    var poster: some View {
        if let imageURL = viewModel.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: Constants.cornerRadius))
                case .failure:
                    posterPlaceholder { noImageIcon }
                default:
                    posterPlaceholder { ProgressView() }
                }
            }
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical) { height, _ in
                height * Constants.posterHeightRatio
            }
            .accessibilityHidden(true)
        } else {
            noImageIcon
                .frame(maxWidth: .infinity, minHeight: Constants.fallbackHeight)
                .background(.quaternary, in: .rect(cornerRadius: Constants.cornerRadius))
                .accessibilityHidden(true)
        }
    }

    func posterPlaceholder(@ViewBuilder content: () -> some View) -> some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(.quaternary)
            .aspectRatio(Constants.posterAspectRatio, contentMode: .fit)
            .overlay(content: content)
    }

    var noImageIcon: some View {
        Image(systemName: "tv")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Header

private extension DetailView {

    var header: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            Text(viewModel.title)
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)

            if let genres = viewModel.genres {
                Text(genres)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Constants.metadataSpacing) {
                    ratingLabel
                    metadataText
                }
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    ratingLabel
                    metadataText
                }
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    var ratingLabel: some View {
        if let rating = viewModel.rating {
            Label {
                Text("\(Text(rating).fontWeight(.semibold))\(Text("/10").foregroundStyle(.secondary))")
            } icon: {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rated \(rating) out of 10")
        } else {
            Label("Not rated yet", systemImage: "star")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var metadataText: some View {
        if let metadata = viewModel.metadata {
            Text(metadata)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Summary

private extension DetailView {

    var summarySection: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            Text("Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if let summary = viewModel.summary {
                Text(summary)
                    .textSelection(.enabled)
            } else {
                Text("No summary available.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG

#Preview("Complete") {
    NavigationStack {
        DetailViewBuilderMock().build()
    }
}

#Preview("Without image") {
    NavigationStack {
        DetailViewBuilderMock().build(show: .mockWithoutImage)
    }
}

#Preview("Without rating and genres") {
    NavigationStack {
        DetailViewBuilderMock().build(show: .mockWithoutRatingAndGenres)
    }
}

#Preview("Without summary") {
    NavigationStack {
        DetailViewBuilderMock().build(show: .mockWithoutSummary)
    }
}

#Preview("Long content") {
    NavigationStack {
        DetailViewBuilderMock().build(show: .mockLongContent)
    }
}

#endif
