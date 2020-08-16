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

    var title: LocalizedStringKey {
        if selection >= feeders.count {
            return "Add a new feeder"
        }
        if let name = feeders[selection].name {
            #warning("FIXME: Name is not refreshed when updating from settings.")
            return "\(name)'s Feeder"
        }
        return "Cat feeder"
    }

    var body: some View {
        ZStack(alignment: .top) {
            #warning("TODO: When no feeder, undefined behavior, should propose feeder association instead")
            TabView(selection: $selection) {
                ForEach(feeders.indices) { index in
                    FeederBoard(feeder: feeders[index]).tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(gradient:
                        Gradient(stops: [
                            .init(color: .background, location: 0),
                            .init(color: .background, location: 0.85),
                            .init(color: Color.background.opacity(0), location: 1)
                        ]), startPoint: .top, endPoint: .bottom)
                    )
                    .ignoresSafeArea(.container, edges: .top)
                    .frame(height: 60)
                HStack {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .padding(.top)
                        .padding(.horizontal, 24)
                        .animation(.none)
                    Spacer()
                }
            }
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
