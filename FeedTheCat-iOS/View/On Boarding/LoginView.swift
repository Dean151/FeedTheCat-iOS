//
//  LoginView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas Durand on 11/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Welcome!")
                    .font(.largeTitle)
                Spacer()
            }

            Spacer()
            Spacer()

            FeederView(isReachable: false)
                .aspectRatio(360/560, contentMode: .fit)
                .padding(.horizontal, 66)

            Spacer()
            Spacer()

            SignInWithAppleView()
                .frame(height: 60)

            Text("Sign in with Apple allow to secure your feeder by associating it with your Apple account.")
        }
        .padding(24)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
