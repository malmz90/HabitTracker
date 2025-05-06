import SwiftUI
import CoreData

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
            // Om redan avklarad idag, återställ
            habit.lastCompletedDate = nil
            habit.currentStreak = max(0, habit.currentStreak - 1)
            habit.isCompletedForMission = false
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
            habit.isCompletedForMission = true  // Lägg till denna rad
        }
        
        do {
            try viewContext.save()
            
            // Uppdatera uppdrag efter att en vana har ändrats
            updateMissions()
        } catch {
            print("Kunde inte spara: \(error)")
        }
    }
    
    // Uppdaterar uppdrag baserat på slutförda vanor
    private func updateMissions() {
        // Räkna slutförda vanor för idag, OCH som är markerade för uppdrag
        let completedTodayPredicate = NSPredicate(format: "lastCompletedDate != nil AND lastCompletedDate >= %@ AND isCompletedForMission == true", Calendar.current.startOfDay(for: Date()) as NSDate)
        
        // Fetch request för att räkna alla vanor slutförda idag
        let habitsRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitsRequest.predicate = completedTodayPredicate
        
        do {
            // Totala antalet slutförda vanor idag
            let completedHabitsCount = try viewContext.count(for: habitsRequest)
            
            // Hämta och uppdatera alla uppdrag
            let missionsRequest: NSFetchRequest<DailyMission> = DailyMission.fetchRequest()
            let missions = try viewContext.fetch(missionsRequest)
            
            for mission in missions {
                mission.completedCount = min(Int16(completedHabitsCount), mission.requiredCount)
                mission.isCompleted = mission.completedCount >= mission.requiredCount
            }
            
            try viewContext.save()
        } catch {
            print("Kunde inte uppdatera uppdrag: \(error)")
        }
    }
}
