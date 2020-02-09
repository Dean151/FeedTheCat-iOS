//
//  FeedView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas Durand on 09/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct FeedView: View {
    @State private var name = "Newton"
    @State private var isReachable = true

    @State private var amount: Int = 5
    @State private var confirmFeeding = false

    var body: some View {
        VStack {
            HStack {
                Text("\(name)'s Feeder")
                Spacer()
                Button(action: {}) {
                    Image(systemName: "gear")
                        .font(.largeTitle)
                }
                .disabled(!isReachable)
            }
            .font(.largeTitle)

            Spacer()
            Spacer()

            FeederView(isReachable: isReachable)
                .aspectRatio(360/560, contentMode: .fit)
                .padding(.horizontal, 66)

            Spacer()
            Spacer()

            feedView

            Spacer()
        }
        .padding(24)
        .alert(isPresented: $confirmFeeding) {
            self.feedTheCatAlert
        }
    }

    var feedView: some View {
        VStack(spacing: 24) {
            Stepper("Give \(amount) grams", value: $amount, in: 5...150)
            Button("Feed the cat", action: {
                self.confirmFeeding.toggle()
            })
            .buttonStyle(MainButtonStyle())
            .disabled(!isReachable)
        }
    }

    var feedTheCatAlert: Alert {
        Alert(title: Text("Give \(amount) grams to \(name)?"),
              message: nil,
              primaryButton: .default(Text("Yes, feed"), action: {

              }),
              secondaryButton: .cancel())
    }
}

struct MainButtonStyle: ButtonStyle {

    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        MainButton(configuration: configuration)
    }

    struct MainButton: View {
        let disabledColor = Color("Disabled")
        let configuration: ButtonStyle.Configuration

        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? Color.orange : disabledColor)
                .cornerRadius(4)
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeedView()
                .accentColor(.orange)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone SE"))
                .preferredColorScheme(.dark)
            FeedView()
                .accentColor(.orange)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone 8"))
            FeedView()
                .accentColor(.orange)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone 11"))
        }
    }
}
