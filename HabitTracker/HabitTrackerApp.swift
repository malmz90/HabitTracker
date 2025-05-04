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
            TabView {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Vanor", systemImage: "list.bullet")
                    }
                
                StatsView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Statistik", systemImage: "chart.bar")
                    }
            }
        }
    }
}
