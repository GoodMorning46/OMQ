import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct MealDetailView: View {
    let meal: Meal
    @State private var showAlert = false
    @State private var showSuccess = false

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ✅ Image du repas avec cache
            if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                    .frame(height: 400)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
                    .ignoresSafeArea()
            }

            // ✅ Carte blanche
            VStack(spacing: 0) {
                Spacer().frame(height: 350)

                VStack(alignment: .leading, spacing: 20) {
                    Text("\(meal.name.capitalized)")
                        .font(.system(size: 24, weight: .semibold))

                    // 🔥 Valeurs nutritionnelles
                    if let calories = meal.calories,
                       let proteins = meal.proteinsGrams,
                       let carbs = meal.carbs,
                       let fats = meal.fats {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calories : \(Int(calories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            HStack(spacing: 16) {
                                Spacer()

                                nutritionStat(title: "Protéine", value: Int(proteins), unit: "g")
                                    .frame(maxWidth: .infinity)
                                nutritionStat(title: "Glucide", value: Int(carbs), unit: "g")
                                    .frame(maxWidth: .infinity)
                                nutritionStat(title: "Lipide", value: Int(fats), unit: "g")
                                    .frame(maxWidth: .infinity)

                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)

                        }
                    }

                    // 🧾 Ingrédients + quantités
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingrédients")
                            .font(.headline)

                        ForEach((meal.ingredientQuantities ?? [:]).sorted(by: { $0.key < $1.key }), id: \.key) { ingredient in
                            ingredientRow(
                                icon: emojiForIngredient(ingredient.key),
                                label: ingredient.key.capitalized,
                                value: "\(ingredient.value)g"
                            )
                        }
                    }

                    ingredientRow(icon: "🎯", label: "Catégorie", value: meal.goal)

                    Button(action: {
                        showAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Supprimer ce repas")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .shadow(radius: 10)
            }

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.leading, 16)
            .padding(.top, 60)

            if showSuccess {
                VStack {
                    Spacer().frame(height: 80)
                    Text("✅ Repas supprimé")
                        .padding()
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert("Supprimer ce repas ?", isPresented: $showAlert) {
            Button("Oui", role: .destructive, action: deleteMeal)
            Button("Non", role: .cancel) { }
        } message: {
            Text("Cette action est irréversible.")
        }
        .navigationBarTitle("", displayMode: .inline)        
    }

    private func ingredientRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }
    }

    private func nutritionStat(title: String, value: Int, unit: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text("\(value)\(unit)")
                .fontWeight(.bold)
        }
    }

    private func emojiForIngredient(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        if lowercased.contains("poulet") { return "🍗" }
        if lowercased.contains("pâte") || lowercased.contains("pate") { return "🍝" }
        if lowercased.contains("brocoli") { return "🥦" }
        if lowercased.contains("lentille") { return "🫘" }
        if lowercased.contains("poisson") { return "🐟" }
        return "🍽️"
    }

    private func deleteMeal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("generatedMeals")
            .whereField("mealId", isEqualTo: meal.mealId)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    docs.first?.reference.delete()
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
    }
}

// ✅ Extension pour coins arrondis spécifiques
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
