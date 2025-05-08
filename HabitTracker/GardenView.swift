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
    private let totalSlots = 12
    
    // Hämtar blomman på en specifik position
    private func getFlower(for position: Int) -> PlantedFlower? {
        return plantedFlowers.first(where: { $0.position == Int16(position) })
    }
    
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
    

}
