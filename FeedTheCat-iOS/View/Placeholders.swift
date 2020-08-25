//
//  NoInternet.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 11/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct Authenticating: View {
    var body: some View {
        NavigationView {
            ProgressView() {
                Text("Authenticating…")
                    .font(.title3)
            }
            .foregroundColor(.gray)
            .navigationTitle("Feed The Cat")
        }
    }
}

struct Authenticating_Previews: PreviewProvider {
    static var previews: some View {
        Authenticating()
            .accentColor(.accent)
    }
}

struct NoInternet: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                ZStack {
                    HoneyGuaridanS25()
                        .aspectRatio(360/560, contentMode: .fit)
                        .padding(.horizontal, 66)
                        .opacity(0.33)
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                }
                Text("Your phone seems offline")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(24)
            .navigationTitle("Feed The Cat")
        }
    }
}

struct NoInternet_Previews: PreviewProvider {
    static var previews: some View {
        NoInternet()
            .accentColor(.accent)
    }
}
