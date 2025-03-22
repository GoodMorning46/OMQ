// MealViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth

class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var isLoadingMeals = true

    func fetchGeneratedMeals() {
        print("🔥 fetchGeneratedMeals() est appelé")

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Erreur: utilisateur non authentifié.")
            isLoadingMeals = false
            return
        }
        print("📡 Récupération des repas pour l'utilisateur: \(userId)")

        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("generatedMeals")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Erreur Firestore : \(error.localizedDescription)")
                        self.isLoadingMeals = false
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("❌ Aucun document trouvé.")
                        self.isLoadingMeals = false
                        return
                    }

                    self.meals = documents.compactMap { doc in
                        let data = doc.data()
                        print("📄 Données Firestore reçues : \(data)")

                        guard let name = data["name"] as? String,
                              let description = data["description"] as? String else {
                            print("❌ Données mal formatées pour un repas.")
                            return nil
                        }

                        let imageURL = data["imageURL"] as? String
                        let meal = Meal(name: name, imageURL: imageURL, description: description)
                        print("✅ Repas créé : \(meal)")
                        return meal
                    }

                    print("✅ Nombre total de repas chargés : \(self.meals.count)")
                    self.isLoadingMeals = false

                    print("📸 Vérification des images des repas récupérés:")
                    for meal in self.meals {
                        print("Nom: \(meal.name), Image URL: \(meal.imageURL ?? "Aucune URL")")
                    }
                }
            }
    }
}
