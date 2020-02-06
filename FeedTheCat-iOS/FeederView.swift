//
//  FeederView.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 06/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import SwiftUI

struct FeederView: View {
    @Binding var isReachable: Bool

    private let mainColor = Color("MainFeeder")
    private let secondColor = Color("SecondaryFeeder")
    private let thirdColor = Color("TertiaryFeeder")

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: proxy.size.height * 0.005) {
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
            VStack(spacing: proxy.size.height * 0.0075) {
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
                path.move(to: .zero)
                path.addLine(to: .init(x: amount, y: frame.size.height / 2))
                path.addLine(to: .init(x: 0, y: frame.size.height))
                path.addLine(to: .init(x: frame.size.width, y: frame.size.height))
                path.addLine(to: .init(x: frame.size.width - amount, y: frame.size.height / 2))
                path.addLine(to: .init(x: frame.size.width, y: 0))
            }
            .fill(self.thirdColor)
        }
    }

    private var indicators: some View {
        GeometryReader { proxy in
            ZStack {
                self.indicatorBackground
                self.indicator(color: .red, proxy: proxy, isActive: self.isReachable)
                    .offset(x: -proxy.size.width * 0.25)
                self.indicator(color: .green, proxy: proxy, isActive: self.isReachable)
                    .offset(x: proxy.size.width * 0.25)
            }
        }
    }

    private var indicatorBackground: some View {
        GeometryReader { proxy in
            Path { path in
                let frame = proxy.frame(in: .local)
                let amount = frame.width * 0.15
                path.move(to: .zero)
                path.addQuadCurve(to: .init(x: amount, y: frame.size.height), control: .init(x: 0, y: frame.size.height))
                path.addLine(to: .init(x: frame.size.width - amount, y: frame.size.height))
                path.addQuadCurve(to: .init(x: frame.size.width, y: 0), control: .init(x: frame.size.width, y: frame.size.height))
            }
            .fill(self.mainColor)
        }
    }

    private func indicator(color: Color, proxy: GeometryProxy, isActive: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(height: proxy.size.height * 0.2)
            .shadow(color: color, radius: isActive ? proxy.size.height * 0.15 : 0, x: 0, y: 0)
            .brightness(isActive ? 0 : -0.4)
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
        Capsule()
            .fill(self.secondColor)
    }
}

struct FeederView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeederView(isReachable: .constant(false))
                .padding()
                .previewLayout(.fixed(width: 360, height: 560))
            FeederView(isReachable: .constant(true))
                .padding()
                .previewLayout(.fixed(width: 360, height: 560))
        }

    }
}
