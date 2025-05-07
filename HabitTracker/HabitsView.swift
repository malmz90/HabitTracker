import SwiftUI
import CoreData

struct HabitsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.name, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>

    @State private var showingAddHabit = false

    var body: some View {
        NavigationView {
            List {
                ForEach(habits) { habit in
                    HabitItemView(habit: habit)
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Mina Vanor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        Label("Lägg till vana", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }

    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { habits[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Kunde inte radera vana: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct HabitsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
