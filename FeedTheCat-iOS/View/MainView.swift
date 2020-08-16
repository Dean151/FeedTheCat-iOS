//
//  MainView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 11/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import UIKit
import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @Namespace var namespace

    var body: some View {
        Group {
            switch appState.state {
            case .loading:
                Authenticating()
                    .onAppear {
                        appState.restoreSession()
                    }
            case .noInternetConnexion:
                NoInternet()
            case .notLoggedIn:
                LoginForm()
            case .loggedIn(user: let user):
                FeederList(feeders: user.feeders)
            }
        }
        .accentColor(.accent)
        .onAppear(perform: setupAppearance)
    }

    private func setupAppearance() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "Accent")
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView().environmentObject(AppState.loading)
            MainView().environmentObject(AppState.notLoggedIn)
            MainView().environmentObject(AppState.noInternet)
        }
    }
}
