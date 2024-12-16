//
//  EventTapperApp.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 1/11/24.
//

import SwiftUI
import PredicateView
import EventTapCore

@main
struct EventTapperApp: App {
    let coordinator = Coordinator()
    let eventCoordinator = EventTapCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .environment(eventCoordinator)
        }
        
        Settings {
            SettingsView(coordinator: coordinator)
        }
    }
}
