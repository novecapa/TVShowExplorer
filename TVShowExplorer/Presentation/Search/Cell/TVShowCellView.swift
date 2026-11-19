//
//  TVShowCellView.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import SwiftUI

struct TVShowCellView: View {

    private enum Constants {
        static let imageWidth: CGFloat = 60
        static let imageHeight: CGFloat = 84
        static let cornerRadius: CGFloat = 6
        static let spacing: CGFloat = 12
    }

    let show: TVShow

    var body: some View {
        HStack(spacing: Constants.spacing) {
            AsyncImage(url: show.mediumImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "tv")
                    .foregroundStyle(.secondary)
            }
            .frame(width: Constants.imageWidth, height: Constants.imageHeight)
            .background(.quaternary)
            .clipShape(.rect(cornerRadius: Constants.cornerRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(show.name)
                    .font(.headline)

                if let genres = show.formattedGenres {
                    Text(genres)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if let rating = show.formattedRating() {
                        Image(systemName: "star.fill")
                        Text(rating)
                    }
                    if let year = show.premiereYear {
                        Text(year)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG

#Preview {
    List {
        TVShowCellView(show: .mock)
    }
}

#endif
