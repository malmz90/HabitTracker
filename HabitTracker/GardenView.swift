import SwiftUI
import CoreData

struct GardenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default)
    private var users: FetchedResults<User>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PlantedFlower.position, ascending: true)],
        animation: .default)
    private var plantedFlowers: FetchedResults<PlantedFlower>
    
    // Användarens diamantvaluta
    private var diamonds: Int {
        return Int(users.first?.diamonds ?? 0)
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)
    private let totalSlots = 9
    
    @State private var selectedSlot: Int? = nil
    @State private var showingPlantingOptions = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header med diamanter
                HStack {
                    Text("Min Trädgård")
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
                
                // Visar sammanfattning
                Text("Blommor: \(plantedFlowers.count) / \(totalSlots)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                
                // Grid med planteringsplatser
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(0..<totalSlots, id: \.self) { index in
                        if let flower = getFlower(for: index) {
                            // Visa planterad blomma
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 120)
                                    .border(Color.gray.opacity(0.3), width: 1)
                                
                                Text(flower.emojiSymbol ?? "🌱")
                                    .font(.system(size: 40))
                            }
                        } else {
                            // Visa tom planteringsplats
                            Button(action: {
                                selectedSlot = index
                                showingPlantingOptions = true
                            }) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 120)
                                    .border(Color.gray.opacity(0.3), width: 1)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .sheet(isPresented: $showingPlantingOptions) {
                if let slot = selectedSlot {
                    PlantingOptionsView(slot: slot) {
                        showingPlantingOptions = false
                    }
                }
            }
        }
    }
    
    // Hämtar blomman på en specifik position
    private func getFlower(for position: Int) -> PlantedFlower? {
        return plantedFlowers.first(where: { $0.position == Int16(position) })
    }
    
    
}

struct PlantingOptionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default)
    private var users: FetchedResults<User>
    
    let slot: Int
    let onDismiss: () -> Void
    
    // Tillgängliga blommor med pris
    private let availableFlowers = [
        ("leaf", "🌿", 5),
        ("shrub", "🌳", 50),
        ("flower", "🌷", 20)
    ]
    
    // Användarens diamantvaluta
    private var diamonds: Int {
        return Int(users.first?.diamonds ?? 0)
    }
    
    var body: some View {
        VStack {
            Text("Vad vill du plantera?")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(availableFlowers, id: \.0) { flowerType, emoji, cost in
                        HStack {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "diamond.fill")
                                    .foregroundColor(.blue)
                                Text("\(cost)")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button("PLANTERA") {
                                plantFlower(type: flowerType, symbol: emoji, cost: cost)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(diamonds >= cost ? Color.gray : Color.gray.opacity(0.3))
                            .foregroundColor(diamonds >= cost ? .white : .gray)
                            .cornerRadius(8)
                            .disabled(diamonds < cost)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Button("Stäng") {
                onDismiss()
            }
            .padding()
        }
        .frame(maxWidth: 350)
    }
    
    private func plantFlower(type: String, symbol: String, cost: Int) {
        guard let user = users.first, user.diamonds >= Int32(cost) else { return }
        
        // Skapa en ny planterad blomma
        let newFlower = PlantedFlower(context: viewContext)
        newFlower.id = UUID()
        newFlower.position = Int16(slot)
        newFlower.flowerType = type
        newFlower.emojiSymbol = symbol
        newFlower.plantedDate = Date()
        
        // Dra av diamanter
        user.diamonds -= Int32(cost)
        
        // Spara ändringar
        do {
            try viewContext.save()
            onDismiss()
        } catch {
            print("Kunde inte plantera blomma: \(error)")
        }
    }
}


