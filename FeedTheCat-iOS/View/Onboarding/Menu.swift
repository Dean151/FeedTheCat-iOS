//
//  Menu.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 11/09/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct AdminMenu: View {
    var body: some View {
        Form() {
            Section {
                Button(action: {}, label: {
                    Text("Logout")
                }).foregroundColor(.red)
            }
        }
    }
}

struct AdminMenu_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminMenu()
        }.accentColor(.accent)
    }
}
