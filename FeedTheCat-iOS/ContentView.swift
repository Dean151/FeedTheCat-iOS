//
//  ContentView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 06/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct FeederView: View {
    @Binding var isActive: Bool

    private let mainColor = Color("MainFeeder")
    private let secondColor = Color("SecondaryFeeder")
    private let thirdColor = Color("TertiaryFeeder")

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 6) {
                self.top.frame(height: proxy.size.height * 0.4)
                self.middle.frame(height: proxy.size.height * 0.1)
                self.bottom.frame(height: proxy.size.height * 0.45)
            }
        }
        .preferredColorScheme(.light)
        .drawingGroup()
    }

    private var top: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: proxy.size.width * 0.025)
                .fill(self.mainColor)
        }
    }

    private var middle: some View {
        GeometryReader { proxy in
            ZStack {
                self.middleBody
                    .padding(.horizontal, proxy.size.width * 0.05)
                self.indicators
                    .frame(width: proxy.size.width * 0.3, height: proxy.size.height * 0.4)
                    .offset(y: -proxy.size.height * 0.2)

                self.button
                    .frame(height: proxy.size.height * 0.25)
                    .offset(y: proxy.size.height * 0.25)
            }
        }
    }

    private var bottom: some View {
        GeometryReader { proxy in
            VStack(spacing: 2) {
                ZStack {
                    self.top
                    self.drawer
                }
                HStack(spacing: proxy.size.width * 0.4) {
                    self.foot
                    self.foot
                }
                .padding(.horizontal, proxy.size.width * 0.1)
                .frame(height: proxy.size.height * 0.04)
            }
        }
    }

    private var middleBody: some View {
        GeometryReader { proxy in
            Path { path in
                let frame = proxy.frame(in: .local)
                let amount = frame.width * 0.035
                path.move(to: frame.origin)
                path.addLine(to: .init(x: frame.origin.x + amount, y: frame.size.height / 2))
                path.addLine(to: .init(x: frame.origin.x, y: frame.size.height))
                path.addLine(to: .init(x: frame.size.width, y: frame.size.height))
                path.addLine(to: .init(x: frame.size.width - amount, y: frame.size.height / 2))
                path.addLine(to: .init(x: frame.size.width, y: frame.origin.y))
            }
            .fill(self.thirdColor)
        }
    }

    private var indicators: some View {
        ZStack {
            Rectangle()
                .fill(self.mainColor)
        }
    }

    private var button: some View {
        Circle()
            .fill(self.mainColor)
    }

    private var drawer: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(self.secondColor)
                .frame(width: proxy.size.width * 0.7, height: proxy.size.height * 0.25)
                .offset(y: proxy.size.height * 0.25)
        }
    }

    private var foot: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: proxy.size.height / 2)
                .fill(self.secondColor)
        }
    }
}

struct FeederView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeederView(isActive: .constant(false))
                .padding()
                .previewLayout(.fixed(width: 360, height: 560))
            FeederView(isActive: .constant(true))
                .padding()
                .previewLayout(.fixed(width: 360, height: 560))
        }

    }
}
