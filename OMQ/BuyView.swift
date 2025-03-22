//
//  BuyView.swift
//  OMQ
//
//  Created by Benjamin Lanery on 02/01/2025.
//

import SwiftUI

struct BuyView: View {
    // MARK: - Properties
    @State private var items: [ShoppingItem] = []
    @FocusState private var focusedItemID: UUID? // ID de l'élément actuellement en focus
    
    // MARK: - Computed Properties
    private var allItemsChecked: Bool {
        !items.isEmpty && items.allSatisfy { $0.isChecked }
    }
    
    // MARK: - Functions
    private func addNewItem() {
        let newItem = ShoppingItem(id: UUID(), name: "", isChecked: false)
        items.append(newItem)
        focusedItemID = newItem.id // Active le focus sur le nouvel élément
    }
    
    private func deleteItems(at offsets: IndexSet) {
        guard !offsets.isEmpty else { return }
        items.remove(atOffsets: offsets)
    }
    
    private func clearAllItems() {
        focusedItemID = nil // Retire le focus
        DispatchQueue.main.async {
            self.items.removeAll() // Vide la liste après avoir retiré le focus
        }
    }
    
    // MARK: - Body
    // MARK: - Body
    var body: some View {
        VStack {
            Text("Liste de courses") // Le titre
                .font(.custom("SFProText-Bold", size: 25)) // Utilise une police spécifique
                .frame(maxWidth: .infinity, alignment: .leading) // Aligne à gauche
                .padding(.bottom, 10) // Espacement
            
            ScrollView {
                LazyVStack {
                    ForEach($items, id: \.id) { $item in
                        HStack {
                            TextField("Nouvel élément", text: $item.name)
                                .focused($focusedItemID, equals: item.id)
                                .onSubmit { focusedItemID = nil }
                                .strikethrough(item.isChecked, color: .gray)
                                .foregroundColor(item.isChecked ? .gray : .black)
                                .font(.custom("SFProText-Bold", size: 20))
                            
                            Spacer()
                            
                            Button(action: {
                                item.isChecked.toggle()
                            }) {
                                Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(item.isChecked ? .green : .gray)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            
            Spacer()
            
            ZStack {
                Button(action: clearAllItems) {
                    HStack {
                            Text("Terminer")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                            }
                        .frame(height: 50)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(allItemsChecked ? Color.green : Color.white)
                        .foregroundColor(.white)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5) // Ajout de l'ombre
                }
                .disabled(items.isEmpty || !allItemsChecked) // Désactive si la liste est vide ou non cochée
                
                Button(action: addNewItem) {
                    Text("Ajouter")
                        .frame(width: 100, height: 40)
                        .font(.headline)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(40)
                        .shadow(radius: 3)
                }
                .offset(x: UIScreen.main.bounds.width / 2.1 - 90, y: 0) // Positionne "Ajouter" légèrement au-dessus du bouton "Terminer"
                .padding(10)
            }
            .padding(.bottom, 20)
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 10, trailing: 20))
    }
}

// MARK: - ShoppingItem Struct
struct ShoppingItem: Identifiable {
    let id: UUID
    var name: String
    var isChecked: Bool
}

// MARK: - Preview
#Preview {
    BuyView()
}
