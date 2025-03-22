import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MealDetailView: View {
    let meal: Meal
    @State private var showAlert = false
    @State private var showSuccess = false
    @State private var isEditing = false
    @State private var editedName: String = ""
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // ✅ Zone image en haut
                ZStack {
                    if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .ignoresSafeArea(.container, edges: .top) // 👈 Ajout ici
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.gray)
                            case .empty:
                                ProgressView()
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }

                // ✅ Partie blanche avec infos
                VStack(alignment: .leading, spacing: 16) {
                    if isEditing {
                        TextField("Nouveau nom du plat", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title2)
                    } else {
                        Text(meal.name)
                            .font(.system(size: 28, weight: .bold))
                    }

                    Text(meal.description ?? "Pas de description.")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if isEditing {
                        Button {
                            updateMealName()
                        } label: {
                            Label("Valider", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button("Modifier le nom") {
                            editedName = meal.name
                            isEditing = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                    }

                    Button("Supprimer le repas") {
                        showAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)

                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .offset(y: -30)
                .shadow(radius: 10)
            }

            // ✅ Bouton retour sur l’image
            // ✅ Bouton retour sur l’image
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.leading, 16)
                .padding(.top, 50)
            }

            // ✅ Toast succès
            if showSuccess {
                VStack {
                    Spacer().frame(height: 80)
                    Text("✅ Modification réussie")
                        .padding()
                        .background(Color.green.opacity(0.95))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSuccess = false
                                    isEditing = false
                                }
                            }
                        }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .alert("Supprimer ce repas ?", isPresented: $showAlert) {
            Button("Oui", role: .destructive, action: deleteMeal)
            Button("Non", role: .cancel) { }
        } message: {
            Text("Cette action est irréversible.")
        }
        .navigationBarBackButtonHidden(true)
    }
    

    // MARK: 🔥 Mise à jour du nom
    private func updateMealName() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("generatedMeals")
            .whereField("name", isEqualTo: meal.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Erreur mise à jour : \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else { return }

                document.reference.updateData(["name": editedName]) { error in
                    if error == nil {
                        showSuccess = true
                    }
                }
            }
    }

    // MARK: 🔥 Suppression
    private func deleteMeal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("generatedMeals")
            .whereField("name", isEqualTo: meal.name)
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
        return Path(UIBezierPath(roundedRect: rect,
                                 byRoundingCorners: corners,
                                 cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
