//
//  SignInWithAppleView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas Durand on 11/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import AuthenticationServices
import SwiftUI

struct SignInWithAppleView: UIViewRepresentable {

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .default, style: context.environment.colorScheme == .dark ? .white : .black)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        
    }
}

struct SignInWithAppleView_Preview: PreviewProvider {
    static var previews: some View {
        SignInWithAppleView()
    }
}

