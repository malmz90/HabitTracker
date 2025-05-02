//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Alexander Malmqvist on 2025-05-02.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
