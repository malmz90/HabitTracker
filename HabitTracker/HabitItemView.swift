import SwiftUI

struct HabitItemView: View {
    @ObservedObject var habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.name ?? "Okänd vana")
                    .font(.headline)
                
                Text("Streak: \(habit.currentStreak) dagar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                toggleCompletion()
            }) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompletedToday() ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Kontrollerar om vanan är markerad som slutförd idag
    private func isCompletedToday() -> Bool {
        guard let lastCompletedDate = habit.lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastCompletedDate)
    }
    
    // Markerar vanan som slutförd/ej slutförd och uppdaterar streak
    private func toggleCompletion() {
        let today = Date()
        
        if isCompletedToday() {
            // Om redan avklarad idag, återställ
            habit.lastCompletedDate = nil
            habit.currentStreak = max(0, habit.currentStreak - 1)
        } else {
            // Markera som avklarad
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
            
            // Om senaste slutförandedatum var igår, öka streak
            if let lastDate = habit.lastCompletedDate,
               let yesterday = yesterday,
               Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                habit.currentStreak += 1
            } else if habit.lastCompletedDate == nil ||
                     !Calendar.current.isDateInYesterday(habit.lastCompletedDate!) {
                // Om det inte var igår, börja ny streak
                habit.currentStreak = 1
            }
            
            habit.lastCompletedDate = today
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Kunde inte spara: \(error)")
        }
    }
}
