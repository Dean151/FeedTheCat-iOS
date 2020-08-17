//
//  FeederBoard.swift
//  FeedTheCat-iOS
//
//  Created by Thomas Durand on 09/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import os.log
import SwiftUI

struct FeederBoard: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var feeder: Feeder

    @State private var state: FeederState = .unknown
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    @State private var amount = 5
    @State private var confirmFeeding = false
    @State private var isFeeding = false
    @State private var feedNowStatus: Networking.StatusResponse?

    @State private var showSettings = false

    let relativeFormatter: RelativeDateTimeFormatter = {
        RelativeDateTimeFormatter()
    }()

    func updateFeederState() {
        os_log("Will check state for feeder: %d", type: .debug, feeder.id)
        appState.checkFeederStatus(feeder: feeder, updated: {
            if case .unknown = $0 { return }
            self.state = $0
            os_log("Retreived state for feeder: %d -> %@", type: .debug, feeder.id, $0)
        })
    }

    func feedTheCat() {
        if isFeeding { return }
        do {
            try appState.feedNow(feeder: feeder, quantity: amount) {
                withAnimation {
                    self.isFeeding = false
                }
                self.feedNowStatus = $0
            }
            withAnimation {
                isFeeding = true
            }
        } catch {
            amount = min(Amount.max, max(Amount.min, amount))
        }
    }

    var body: some View {
        VStack {
            Spacer()

            GeometryReader { proxy in
                HoneyGuaridanS25(isReachable: state.isReachable)
                    .opacity(state.isReachable ? 1 : 0.33)
                    .onChange(of: proxy.frame(in: .global).center) { center = $0 }
            }
            .aspectRatio(360/560, contentMode: .fit)
            .padding(.horizontal, 66)
            if case let .notAvailable(lastReachDate: date) = state {
                if let date = date {
                    Label("Last uptime \(date, formatter: relativeFormatter)", systemImage: "bolt.horizontal")
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .renderingMode(.original)
                        Text("The feeder have never been up!")
                            .foregroundColor(.secondary)
                    }
                }
            } else if case .unknown = state {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Reconnecting…")
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            feedView
                .onChange(of: amount, perform: { _ in
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                })
                .onChange(of: confirmFeeding, perform: { value in
                    if value {
                        let generator = UIImpactFeedbackGenerator()
                        generator.impactOccurred()
                    }
                })
        }
        .gesture(circularGesture)
        .padding(.horizontal, 24)
        .padding(.vertical, 50)
        .sheet(isPresented: $showSettings) {
            FeederSettings(feeder: feeder)
                .accentColor(.accent)
                .environmentObject(appState)
        }
        .actionSheet(isPresented: $confirmFeeding) {
            self.confirmFeedOrder
        }
        .alert(item: $feedNowStatus) { status in
            status.success ? feededAlert : couldntFeedAlert
        }
        .onAppear {
            amount = feeder.defaultAmount ?? Amount.min
            updateFeederState()
        }
        .onReceive(timer) { _ in
            updateFeederState()
        }
        .onChange(of: state, perform: { value in
            if value == .available {
                return
            }
            // Feeder unavailable, close everything
            showSettings = false
            confirmFeeding = false
        })
    }

    let formatter: MassFormatter = {
        let formatter = MassFormatter()
        formatter.unitStyle = .long
        return formatter
    }()

    var feedAmountString: String {
        formatter.string(fromValue: Double(amount), unit: .gram)
    }

    var feedView: some View {
        VStack(spacing: 24) {
            Stepper("Give \(feedAmountString)", value: $amount, in: Amount.min...Amount.max)
            HStack {
                Button(action: {
                    if isFeeding { return }
                    self.confirmFeeding.toggle()
                }) {
                    HStack(spacing: 8) {
                        if isFeeding {
                            ProgressView()
                                .colorScheme(.dark)
                        }
                        Text("Feed the cat")
                    }
                }
                .buttonStyle(MainButtonStyle())
                .accessibility(hint: Text(feeder.name != nil ? "Will give \(amount) grams to \(feeder.name!)." : "Will give \(amount) grams to the cat."))

                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.largeTitle)
                }.accessibility(label: Text("Feeder settings"))
            }
            .disabled(!state.isReachable)
        }
    }

    @State private var center: CGPoint = .zero
    @State private var clockwizeTours = 0
    @State private var previousAmount: Int?
    @State private var previousLocation: CGPoint?
    var circularGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if previousAmount == nil {
                    previousAmount = amount
                }
                if let previousLocation = previousLocation {
                    let diff = Geometry.angle(between: value.location, and: previousLocation, with: center)
                    if abs(diff) > .pi {
                        if diff > 0 {
                            clockwizeTours += 1
                        } else {
                            clockwizeTours -= 1
                        }
                    }
                }
                let angle = (2 * .pi * CGFloat(clockwizeTours)) + Geometry.angle(between: value.startLocation, and: value.location, with: center)
                amount = max(Amount.min, min(Amount.max, previousAmount! + Int((angle * 50) / (2 * .pi))))
                previousLocation = value.location
            }
            .onEnded { _ in
                clockwizeTours = 0
                previousLocation = nil
                previousAmount = nil
            }
    }

    var confirmFeedOrder: ActionSheet {
        ActionSheet(title: Text(feeder.name != nil ? "Give \(amount) grams to \(feeder.name!)?" : "Give \(amount) grams to the cat?"), buttons: [
            .default(Text("Yes, feed the cat"), action: feedTheCat),
            .cancel()
        ])
    }

    var feededAlert: Alert {
        Alert(title: Text(feeder.name != nil ? "\(feeder.name!) have been feeded!" : "The cat have been feeded!"))
    }
    var couldntFeedAlert: Alert {
        Alert(title: Text("The meal order couldn't reach the feeder. Please try again later."))
    }
}

struct FeederBoard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeederBoard(feeder: Feeder(id: 1, name: "Newton", defaultAmount: 5))
        }
        .accentColor(.accent)
        .environmentObject(AppState.standard)
    }
}
