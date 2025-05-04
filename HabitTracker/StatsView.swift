//
//  StatsView.swift
//  HabitTracker
//
//  Created by Alexander Malmqvist on 2025-05-04.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.name, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    @State private var selectedTimeFrame: TimeFrame = .day
    
    enum TimeFrame {
        case day, week, month
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Tidsperiod", selection: $selectedTimeFrame) {
                    Text("Dag").tag(TimeFrame.day)
                    Text("Vecka").tag(TimeFrame.week)
                    Text("Månad").tag(TimeFrame.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                

                ScrollView {
                    VStack(spacing: 16) {
                        StatsSummaryCard(
                            title: "Sammanfattning",
                            total: habits.count,
                            completed: completedHabits(),
                            completionRate: completionRate()
                        )
                                         
                        ForEach(habits) { habit in
                            HabitStatsRow(
                                habit: habit,
                                isCompletedInTimeFrame: isHabitCompletedInTimeFrame(habit: habit)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistik")
        }
    }
    
    private func isHabitCompletedInTimeFrame(habit: Habit) -> Bool {
        guard let lastCompletedDate = habit.lastCompletedDate else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFrame {
        case .day:
            return calendar.isDateInToday(lastCompletedDate)
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return lastCompletedDate >= startOfWeek
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return lastCompletedDate >= startOfMonth
        }
    }
    
    private func completedHabits() -> Int {
        return habits.filter { isHabitCompletedInTimeFrame(habit: $0) }.count
    }
    
    private func completionRate() -> Double {
        if habits.isEmpty { return 0 }
        return Double(completedHabits()) / Double(habits.count) * 100
    }
}

struct StatsSummaryCard: View {
    let title: String
    let total: Int
    let completed: Int
    let completionRate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Totalt:")
                    Text("Slutförda:")
                    Text("Slutförandegrad:")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(total)")
                    Text("\(completed)")
                    Text(String(format: "%.1f%%", completionRate))
                }
            }
            
            // Progressbar
            ProgressView(value: completionRate, total: 100)
                .accentColor(.green)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct HabitStatsRow: View {
    let habit: Habit
    let isCompletedInTimeFrame: Bool
    
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
                     
            Image(systemName: isCompletedInTimeFrame ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isCompletedInTimeFrame ? .green : .gray)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
