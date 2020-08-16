//
//  ButtonStyles.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 11/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        MainButton(configuration: configuration)
    }

    struct MainButton: View {
        let configuration: ButtonStyle.Configuration

        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            Group {
                configuration.label
            }
            .foregroundColor(.white)
            .accentColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.accentColor : .disabled)
            .brightness(configuration.isPressed && isEnabled ? 0.2 : 0)
            .cornerRadius(4)
        }
    }
}
