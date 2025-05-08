//
//  PlantingOptionsView.swift
//  HabitTracker
//
//  Created by Alexander Malmqvist on 2025-05-08.
//

import SwiftUI
import CoreData

struct PlantingOptionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default)
    private var users: FetchedResults<User>
    
    //parameter slot som användaren klickade på
    let slot: Int
    let onDismiss: () -> Void
    
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
    
        do {
            try viewContext.save()
            onDismiss()
        } catch {
            print("Kunde inte plantera blomma: \(error)")
        }
    }
}


struct PlantingOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PlantingOptionsView(slot: 0, onDismiss: {})
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
