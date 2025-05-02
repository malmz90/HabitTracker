import SwiftUI

struct AddHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var habitName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ny vana")) {
                    TextField("Vad vill du bli bättre på?", text: $habitName)
                }
                
                Section {
                    Button("Lägg till") {
                        addHabit()
                    }
                    .disabled(habitName.isEmpty)
                }
            }
            .navigationTitle("Lägg till ny vana")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addHabit() {
        let newHabit = Habit(context: viewContext)
        newHabit.id = UUID()
        newHabit.name = habitName
        newHabit.currentStreak = 0
        newHabit.lastCompletedDate = nil
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Kunde inte spara ny vana: \(error)")
        }
    }
}
