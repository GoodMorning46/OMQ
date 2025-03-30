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

                        guard let mealId = data["mealId"] as? Int,
                              let protein = data["protein"] as? String,
                              let starchy = data["starchy"] as? String,
                              let vegetable = data["vegetable"] as? String else {
                            print("❌ Données manquantes ou incorrectes")
                            return nil
                        }

                        let imageURL = data["imageURL"] as? String

                        let meal = Meal(
                            mealId: mealId,
                            protein: protein,
                            starchy: starchy,
                            vegetable: vegetable,
                            imageURL: imageURL
                        )

                        print("✅ Repas converti : \(meal)")
                        return meal
                    }

                    print("✅ Nombre total de repas chargés : \(self.meals.count)")
                    self.isLoadingMeals = false

                    print("📸 Vérification des images des repas récupérés:")
                    for meal in self.meals {
                        print("Protéine: \(meal.protein), Féculent: \(meal.starchy), Légume: \(meal.vegetable), Image URL: \(meal.imageURL ?? "Aucune URL")")
                    }
                }
            }
    }
}
