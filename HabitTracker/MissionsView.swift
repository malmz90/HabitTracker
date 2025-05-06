import SwiftUI
import CoreData

struct MissionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyMission.creationDate, ascending: true)],
        animation: .default)
    private var missions: FetchedResults<DailyMission>
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default)
    private var users: FetchedResults<User>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.name, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    // Användarens diamantvaluta
    private var diamonds: Int {
        return Int(users.first?.diamonds ?? 0)
    }
    
    // Tid kvar tills uppdragen återställs
    @State private var timeRemaining: String = ""
    @State private var showResetConfirmation = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header med diamanter
                HStack {
                    Text("Dagliga uppdrag")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.blue)
                        Text("\(diamonds)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding()
                
                // Tid kvar
                HStack {
                    Image(systemName: "clock")
                    Text(timeRemaining)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                .onReceive(timer) { _ in
                    updateTimeRemaining()
                }
                
                // TEMPORÄR ÅTERSTÄLLNINGSKNAPP
                Button(action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Återställ uppdrag")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.bottom)
                .alert(isPresented: $showResetConfirmation) {
                    Alert(
                        title: Text("Återställ uppdrag"),
                        message: Text("Är du säker på att du vill återställa alla uppdrag? Detta kommer att generera nya uppdrag baserat på ditt nuvarande antal vanor."),
                        primaryButton: .destructive(Text("Återställ")) {
                            resetDailyMissions()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // Lista med uppdrag
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(missions) { mission in
                            MissionCard(mission: mission, onClaimReward: {
                                claimReward(for: mission)
                            })
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .onAppear {
                checkAndCreateUser()
                checkAndCreateDailyMissions()
                updateTimeRemaining()
            }
        }
    }
    
    // Kontrollerar att det finns en användare och skapar en om det behövs
    private func checkAndCreateUser() {
        if users.isEmpty {
            let newUser = User(context: viewContext)
            newUser.id = UUID()
            newUser.diamonds = 0
            newUser.lastMissionResetDate = Date().startOfDay()
            
            do {
                try viewContext.save()
            } catch {
                print("Kunde inte spara användare: \(error)")
            }
        }
    }
    
    // Kontrollerar och skapar/återställer dagliga uppdrag
    private func checkAndCreateDailyMissions() {
        let today = Date().startOfDay()
        
        // Kontrollera om vi behöver återställa uppdragen
        if let user = users.first, let lastReset = user.lastMissionResetDate {
            if !Calendar.current.isDate(lastReset, inSameDayAs: today) {
                // Ny dag, återställ uppdragen
                resetDailyMissions()
                user.lastMissionResetDate = today
                try? viewContext.save()
            }
        }
        
        // Skapa uppdrag om det behövs
        if missions.isEmpty {
            createDefaultMissions()
        }
        
        // Uppdatera uppdragsstatus baserat på slutförda vanor
        updateMissionProgress()
    }
    
    // Återställer dagliga uppdrag
    private func resetDailyMissions() {
        // Ta bort befintliga uppdrag
        for mission in missions {
            viewContext.delete(mission)
        }
        
        // Återställ spårning av slutförda vanor för uppdrag
        for habit in habits {
            habit.isCompletedForMission = false
        }
        
        try? viewContext.save()
        
        // Skapa nya uppdrag
        createDefaultMissions()
    }
    
    // Skapar dynamiska uppdrag baserat på antalet vanor
    private func createDefaultMissions() {
        let totalHabits = habits.count
        
        if totalHabits == 0 {
            // Om inga vanor finns, skapa ett simpelt uppdrag
            createMission(description: "Lägg till din första vana", required: 1, reward: 5)
            return
        }
        
        // Skapa tre nivåer av uppdrag baserat på antalet vanor
        
        // Nivå 1: Slutför ca 25% av vanorna (minst 1)
        let level1Count = max(1, Int(Double(totalHabits) * 0.25))
        createMission(
            description: "Slutför \(level1Count) \(level1Count == 1 ? "vana" : "vanor")",
            required: Int16(level1Count),
            reward: 5
        )
        
        // Nivå 2: Slutför ca 50% av vanorna (minst 2 om möjligt)
        if totalHabits >= 2 {
            let level2Count = max(2, Int(Double(totalHabits) * 0.5))
            createMission(
                description: "Slutför \(level2Count) vanor",
                required: Int16(level2Count),
                reward: 10
            )
        }
        
        // Nivå 3: Slutför ca 75% av vanorna (minst 3 om möjligt)
        if totalHabits >= 3 {
            let level3Count = max(3, Int(Double(totalHabits) * 0.75))
            createMission(
                description: "Slutför \(level3Count) vanor",
                required: Int16(level3Count),
                reward: 15
            )
        }
        
        // Nivå 4: Slutför alla vanor (om det finns minst 4 vanor)
        if totalHabits >= 4 {
            createMission(
                description: "Slutför alla \(totalHabits) vanor",
                required: Int16(totalHabits),
                reward: 20
            )
        }
    }
    
    // Hjälpfunktion för att skapa ett enskilt uppdrag
    private func createMission(description: String, required: Int16, reward: Int32) {
        let mission = DailyMission(context: viewContext)
        mission.id = UUID()
        mission.missionDescription = description
        mission.requiredCount = required
        mission.completedCount = 0
        mission.reward = reward
        mission.isCompleted = false
        mission.isRewardClaimed = false
        mission.creationDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Kunde inte spara uppdrag: \(error)")
        }
    }
    
    // Uppdaterar uppdragsstatus baserat på slutförda vanor
    private func updateMissionProgress() {
        let completedHabits = habits.filter { $0.lastCompletedDate != nil && Calendar.current.isDateInToday($0.lastCompletedDate!) && !$0.isCompletedForMission }
        
        var newCompletions = 0
        
        // Markera vanorna som räknade för uppdrag
        for habit in completedHabits {
            habit.isCompletedForMission = true
            newCompletions += 1
        }
        
        // Uppdatera uppdragen med de nya slutförda vanorna
        for mission in missions {
            let currentCount = mission.completedCount
            let newCount = min(currentCount + Int16(newCompletions), mission.requiredCount)
            mission.completedCount = newCount
            mission.isCompleted = newCount >= mission.requiredCount
        }
        
        try? viewContext.save()
    }
    
    // Ta emot belöning för ett slutfört uppdrag
    private func claimReward(for mission: DailyMission) {
        guard mission.isCompleted && !mission.isRewardClaimed else { return }
        
        if let user = users.first {
            user.diamonds += mission.reward
            mission.isRewardClaimed = true
            
            try? viewContext.save()
        }
    }
    
    // Uppdaterar tid tills nästa återställning
    private func updateTimeRemaining() {
        let now = Date()
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) {
            let tomorrowMidnight = Calendar.current.startOfDay(for: tomorrow)
            let timeInterval = tomorrowMidnight.timeIntervalSince(now)
            
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            
            timeRemaining = "\(hours) timmar \(minutes) minuter"
        } else {
            timeRemaining = "Okänd tid"
        }
    }
}

// Komponent för att visa ett uppdragskort
struct MissionCard: View {
    let mission: DailyMission
    let onClaimReward: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mission.missionDescription ?? "Okänt uppdrag")
                .font(.headline)
                .strikethrough(mission.isRewardClaimed)
                .foregroundColor(mission.isRewardClaimed ? .secondary : .primary)
            
            // Förloppsindikator
            ProgressView(value: Double(mission.completedCount), total: Double(mission.requiredCount))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            HStack {
                Text("\(mission.completedCount) / \(mission.requiredCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if mission.isCompleted && !mission.isRewardClaimed {
                    Button(action: onClaimReward) {
                        HStack {
                            Text("Hämta")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "diamond.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("\(mission.reward)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else if mission.isRewardClaimed {
                    Text("Hämtad")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Extension för att få start på dagen från ett datum
extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}
