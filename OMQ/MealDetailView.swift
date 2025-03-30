import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MealDetailView: View {
    let meal: Meal
    @State private var showAlert = false
    @State private var showSuccess = false
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ✅ Fond image
            if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 400)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .ignoresSafeArea()
                    default:
                        Color.gray.opacity(0.1).frame(height: 400).ignoresSafeArea()
                    }
                }
            }

            // ✅ Carte blanche
            VStack(spacing: 0) {
                Spacer().frame(height: 350)

                VStack(alignment: .leading, spacing: 20) {
                    Text("🍽️ Ton repas")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.black)

                    ingredientRow(icon: "🥩", label: "Protéine", value: meal.protein)
                    ingredientRow(icon: "🥔", label: "Féculent", value: meal.starchy)
                    ingredientRow(icon: "🥦", label: "Légume", value: meal.vegetable)

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

            // ✅ Bouton retour
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

            // ✅ Toast succès
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
        .navigationBarBackButtonHidden(true)
    }

    // ✅ Ligne d’ingrédient stylisée
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

// Coin arrondi uniquement en haut
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
