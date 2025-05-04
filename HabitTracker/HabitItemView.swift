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
    
   
    private func isCompletedToday() -> Bool {
        guard let lastCompletedDate = habit.lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastCompletedDate)
    }
    

    private func toggleCompletion() {
        let today = Date()
        
        if isCompletedToday() {
         
            habit.lastCompletedDate = nil
            habit.currentStreak = max(0, habit.currentStreak - 1)
        } else {
      
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
            
       
            if let lastDate = habit.lastCompletedDate,
               let yesterday = yesterday,
               Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                habit.currentStreak += 1
            } else if habit.lastCompletedDate == nil ||
                     !Calendar.current.isDateInYesterday(habit.lastCompletedDate!) {
               
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
