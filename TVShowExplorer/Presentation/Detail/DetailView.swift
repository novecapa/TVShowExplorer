//
//  DetailView.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 18/11/2026.
//

import SwiftUI

struct DetailView: View {

    let show: TVShow

    var body: some View {
        Text(show.name)
            .font(.title)
            .navigationTitle(show.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG

#Preview {
    NavigationStack {
        DetailView(show: .mock)
    }
}

#endif
