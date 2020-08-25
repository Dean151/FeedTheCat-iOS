//
//  LoginForm.swift
//  FeedTheCat-iOS
//
//  Created by Thomas Durand on 11/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import AuthenticationServices
import SwiftUI

struct LoginForm: View {
    @EnvironmentObject var appState: AppState

    @State var showError = false

    var body: some View {
        NavigationView {
            VStack() {
                Spacer()

                HoneyGuaridanS25()
                    .aspectRatio(360/560, contentMode: .fit)
                    .padding(.horizontal, 66)

                Spacer()

                SignInWithAppleButton(.continue, onRequest: { request in
                    request.requestedScopes = [.email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        guard let credential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                            showError = true
                            return
                        }
                        appState.attemptLogin(with: credential, onError: {
                            showError = true
                        })
                    case .failure(error: let error):
                        switch (error as! ASAuthorizationError).code {
                        case .canceled, .unknown:
                            break
                        case .failed, .notHandled, .invalidResponse:
                            showError = true
                        @unknown default:
                            showError = true
                        }
                    }
                })
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .padding(.vertical)

                Text("Sign in with Apple allow to secure your feeder by associating it with your Apple account.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
                Link("Privacy policy", destination: URL(string: "https://www.google.com")!)
                    .padding(4)
            }
            .padding(24)
            .navigationTitle(Text("Welcome!"))
            .alert(isPresented: $showError, content: {
                Alert(title: Text("An error has occured while login in. Please try again."))
            })
        }
    }
}

struct LoginForm_Previews: PreviewProvider {
    static var previews: some View {
        LoginForm()
            .accentColor(.accent)
    }
}

struct AssociateFeeder: View {
    var body: some View {
        VStack {
            Spacer()

            HoneyGuaridanS25()
                .aspectRatio(360/560, contentMode: .fit)
                .padding(.horizontal, 66)
                .opacity(0.33)

            Spacer()

            #warning("TODO: Feeder association not yet implemented")
            Button("Associate a feeder", action: {})
                .buttonStyle(MainButtonStyle())
                .disabled(true)
            Text("After association, your feeder will no longer work with its official application, ensuring full security.")
                .font(.footnote)
                .frame(width: 300)
                .multilineTextAlignment(.center)
            Link("Security policy", destination: URL(string: "https://www.google.com")!)
                .padding(4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 50)
    }
}

struct AssociateFeeder_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AssociateFeeder()
        }.accentColor(.accent)
    }
}
