//
//  FeedersView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 12/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import SwiftUI

struct FeederList: View {
    let feeders: [Feeder]

    @State private var selection: Int = 0
    @State private var refresh: Int = 0

    var currentFeeder: Feeder? {
        if selection >= feeders.count {
            return nil
        }
        return feeders[selection]
    }

    #warning("FIXME: Name is not refreshed when updating from settings.")
    var title: LocalizedStringKey {
        guard let feeder = currentFeeder else {
            return "Misc settings"
        }
        if let name = feeder.name {
            return "\(name)'s Feeder"
        }
        return "Cat feeder"
    }

    var body: some View {
        ZStack {
            // WORKAROUND for having always big title with vertical scroll on pagetab
            NavigationView {
                ZStack {
                    EmptyView()
                }
                .navigationTitle(title)
            }

            Group {
                if feeders.isEmpty {
                    AssociateFeederStart()
                } else {
                    TabView(selection: $selection) {
                        ForEach(feeders.indices) { index in
                            FeederBoard(feeder: feeders[index]).tag(index)
                        }
                        AdminMenu().tag(feeders.count)
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .padding(.top, 100)
        }
    }
}

struct FeederList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeederList(feeders: [Feeder(id: 1, name: "Newton", defaultAmount: 5)])
            FeederList(feeders: [
                        Feeder(id: 1, name: "Newton", defaultAmount: 5),
                        Feeder(id: 2, name: "Fake", defaultAmount: 5)
                       ])
            FeederList(feeders: [])
        }.accentColor(.accent)
    }
}
