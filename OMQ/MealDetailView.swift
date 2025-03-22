import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var showSuccess = false

    @State private var isEditing = false
    @State private var editedName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // 🔤 Affichage ou édition du nom
            if isEditing {
                TextField("Nouveau nom du plat", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .padding(.top)
                
                Button {
                    updateMealName()
                } label: {
                    Label("Valider", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text(meal.name)
                    .font(.title2)
                    .padding(.top)

                Button("Modifier le nom") {
                    editedName = meal.name
                    isEditing = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
            }

            Button("Supprimer le repas") {
                showAlert = true
            }
            .foregroundColor(.red)
            .padding(.bottom)

            Spacer()
        }
        .padding()
        .alert("Supprimer ce repas ?", isPresented: $showAlert) {
            Button("Oui", role: .destructive, action: deleteMeal)
            Button("Non", role: .cancel) { }
        } message: {
            Text("Cette action est irréversible.")
        }
        .overlay(
            VStack {
                if showSuccess {
                    Text("✅ Modification réussie")
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccess = false
                                isEditing = false
                            }
                        }
                }
            }
            .animation(.easeInOut, value: showSuccess)
            , alignment: .top
        )
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
                    print("❌ Erreur lors de la mise à jour : \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("❌ Aucun document trouvé à modifier.")
                    return
                }

                document.reference.updateData(["name": editedName]) { error in
                    if let error = error {
                        print("❌ Erreur mise à jour nom : \(error.localizedDescription)")
                    } else {
                        print("✅ Nom mis à jour avec succès !")
                        showSuccess = true
                    }
                }
            }
    }

    // MARK: 🔥 Suppression du repas
    private func deleteMeal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId)
            .collection("generatedMeals")
            .whereField("name", isEqualTo: meal.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Erreur suppression : \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                for doc in documents {
                    doc.reference.delete()
                }

                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
    }
}
