//
//  AppDelegate.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 06/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import SwiftUI

@main
struct FeedTheCat: App {
    @StateObject var appState = AppState.standard

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
        }
    }
}
