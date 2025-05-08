import SwiftUI

@main
struct HabitTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                HabitsView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Vanor", systemImage: "list.bullet")
                    }
                
                MissionsView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Uppdrag", systemImage: "star.fill")
                    }
                
                GardenView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Trädgård", systemImage: "leaf.fill")
                    }
                /*
                StatsView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Label("Statistik", systemImage: "chart.bar")
                    }
                 */
            }
        }
    }
}
