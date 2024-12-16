//
//  SettingsView.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 3/31/24.
//

import SwiftUI
import EventTapCore

struct SettingsView: View {
    @Bindable var coordinator: Coordinator
    
    var body: some View {
        Form {
            Picker("Tap Location", selection: $coordinator.tapLocation) {
                ForEach(TapLocation.allCases, id: \.self) { location in
                    Text(location.name)
                        .help(location.description)
                }
            }
            .pickerStyle(.radioGroup)
            
            Picker("Tap Placement", selection: $coordinator.tapPlacement) {
                ForEach(TapPlacement.allCases, id: \.self) { placement in
                    Text(placement.name)
                        .help(placement.description)
                }
            }
            .pickerStyle(.radioGroup)
            
            TextField("Throttling (ms)", value: $coordinator.throttleDurationMilliseconds, formatter: NumberFormatter())
        }
        .fixedSize()
        .padding()
    }
}
