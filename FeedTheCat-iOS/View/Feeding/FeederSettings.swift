//
//  FeederSettings.swift
//  FeedTheCat-iOS
//
//  Created by Thomas DURAND on 13/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Aln
import SwiftUI

struct FeederSettings: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    @ObservedObject var feeder: Feeder
    @ObservedObject var values: FeederSettingsValues

    @State var isSaving = false
    @State var showError = false

    init(feeder: Feeder) {
        self.feeder = feeder
        self.values = .init(feeder: feeder)
    }

    func save() {
        guard !isSaving else { return }
        isSaving = true
        appState.saveFeederSettings(values, for: feeder) { success in
            self.isSaving = false
            if success {
                self.close()
            } else {
                self.showError = true
            }
        }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("My cat"),
                    footer: Text("Default meal amount is the amount of food given when pressing the physical button of the feeder.")
                ) {
                    HStack {
                        Text("Name")
                            .lineLimit(1)
                        TextField("Kitty", text: $values.name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        #warning("FIXME: The label is truncated in ENG")
                        Text("Default meal amount")
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        AmountPicker("42", amount: $values.defaultAmount)
                    }
                }

                #warning("FIXME: Cannot scroll to last row when keyboard is up")
                planningSection
            }
            .disabled(isSaving)
            .navigationTitle("Feeder settings")
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
            .onAppear {
                appState.loadPlanning(for: feeder, in: values)
            }
        }
        .alert(isPresented: $showError) {
            errorAlert
        }
    }

    var cancelButton: some View {
        Button("Cancel", action: close)
    }

    var saveButton: some View {
        Button(action: save) {
            if isSaving {
                ProgressView()
            } else {
                Text("Save")
            }
        }.disabled(isSaving)
    }

    var errorAlert: Alert {
        Alert(title: Text("An error occured."), message: Text("Some settings might not have been saved. Please try again."))
    }

    let massFormatter: MassFormatter = {
        let formatter = MassFormatter()
        formatter.unitStyle = .long
        return formatter
    }()

    func planResume(for plan: ScheduledFeedingPlan) -> Text {
        Text("\(plan.countEnabled) meals — \(massFormatter.string(fromValue: Double(plan.amount), unit: .gram))")
    }

    @ViewBuilder
    var planningSection: some View {
        if let planning = values.planning {
            switch planning {
            case .success(let plan):
                Section(header: Text("Feeding plan (\(planResume(for: plan)))")) {
                    PlanningList(planning: $values.underlyingPlanning, defaultAmount: values.defaultAmount)
                }
            case .failure:
                Section(header: Text("Feeding plan")) {
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .renderingMode(.original)
                        Text("Couldn't load current feeding plan")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        } else {
            Section(header: Text("Feeding plan")) {
                HStack(spacing: 8) {
                    Spacer()
                    ProgressView()
                    Text("Loading…")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
}

struct FeederSettings_Previews: PreviewProvider {
    static var previews: some View {
        FeederSettings(feeder: Feeder(id: 1, name: "Newton", defaultAmount: 5))
            .accentColor(.accent)
            .environmentObject(AppState.standard)
    }
}

struct AmountPicker: View {
    private let placeholder: LocalizedStringKey
    @Binding private var amount: Int
    private let formatter: MassFormatter

    init(_ placeholder: LocalizedStringKey, amount: Binding<Int>, style: Formatter.UnitStyle = .short) {
        self.placeholder = placeholder
        self._amount = amount
        self.formatter = MassFormatter()
        formatter.unitStyle = style
    }

    var body: some View {
        let amountProxy = Binding<String>(
            get: { String(format: "%d", Int(self.amount)) },
            set: {
                if let value = NumberFormatter().number(from: $0) {
                    self.amount = min(Amount.max, value.intValue)
                }
            }
        )

        return HStack {
            TextField(placeholder, text: amountProxy, onEditingChanged: { _ in applyBounds(proxy: amountProxy) }, onCommit: { applyBounds(proxy: amountProxy) })
                .keyboardType(.numbersAndPunctuation) // Number and punctuation because numberpad have no confirmation button...
                .multilineTextAlignment(.trailing)
            Text(formatter.unitString(fromValue: Double(amount), unit: .gram))
        }
    }

    func applyBounds(proxy: Binding<String>) {
        amount = min(Amount.max, max(Amount.min, amount))
        proxy.wrappedValue = "\(amount)"
    }
}

struct PlanningList: View {
    @Binding var planning: ScheduledFeedingPlan
    let defaultAmount: Int

    var body: some View {
        ForEach(planning) { meal in
            if let index = planning.firstIndex(of: meal), let $meal = Binding($planning[safely: index]) {
                MealRow(meal: $meal)
            } else {
                EmptyView()
            }
        }
        .onDelete(perform: { indexSet in
            planning.remove(atOffsets: indexSet)
        })

        if planning.count < ScheduledFeedingPlan.maxNumberOfMeals {
            Button(action: {
                do {
                    try withAnimation {
                        try planning.add(try ScheduledMeal(amount: try Amount(value: defaultAmount), date: Date(), enabled: true))
                    }
                } catch {}
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .renderingMode(.original)
                    Text("Add new meal")
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct PlanningList_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            Form {
                PlanningList(planning: .constant(.testData), defaultAmount: 5)
                    .accentColor(.accent)
            }
        }.previewLayout(.fixed(width: 414, height: 600))
    }
}

struct MealRow: View {
    @Binding var meal: ScheduledMeal

    var body: some View {
        HStack(spacing: 8) {
            DatePicker("Meal time", selection: $meal.time.date, displayedComponents: [.hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .labelsHidden()
                .frame(minHeight: 44)
            Spacer(minLength: 0)
            AmountPicker("Meal amount", amount: $meal.amount.value)
                .labelsHidden()
            Toggle("Meal enabled", isOn: $meal.isEnabled)
                .labelsHidden()
        }
    }
}

extension Int: Identifiable {
    public var id: Int {
        return self
    }
}
