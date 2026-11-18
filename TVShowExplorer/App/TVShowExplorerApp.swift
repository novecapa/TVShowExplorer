//
//  TVShowExplorerApp.swift
//  TVShowExplorer
//
//  Created by Josep Cerdá Penadés on 17/11/2026.
//

import SwiftUI

@main
struct TVShowExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            SearchViewBuilder().build()
        }
    }
}
