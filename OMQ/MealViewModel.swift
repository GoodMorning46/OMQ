import Foundation
import FirebaseFirestore
import FirebaseAuth

class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var isLoadingMeals = true
    private var hasLoadedMeals = false

    func fetchGeneratedMeals() {
        print("🔥 fetchGeneratedMeals() est appelé")

        guard !hasLoadedMeals else {
            print("⚠️ Repas déjà chargés, on ne refait pas l’appel Firestore")
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Erreur: utilisateur non authentifié.")
            isLoadingMeals = false
            return
        }

        print("📡 Récupération des repas pour l'utilisateur: \(userId)")
        isLoadingMeals = true

        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("generatedMeals")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingMeals = false

                    if let error = error {
                        print("❌ Erreur Firestore : \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("❌ Aucun document trouvé.")
                        return
                    }

                    self.meals = documents.compactMap { doc in
                        let data = doc.data()

                        guard
                            let mealId = data["mealId"] as? Int,
                            let proteins = data["proteins"] as? [String],
                            let starchies = data["starchies"] as? [String],
                            let vegetables = data["vegetables"] as? [String],
                            let name = data["name"] as? String,
                            let goal = data["goal"] as? String,
                            let cuisine = data["cuisine"] as? String,
                            let season = data["season"] as? String
                        else {
                            print("❌ Données manquantes ou incorrectes")
                            return nil
                        }

                        let imageURL = data["imageURL"] as? String
                        let id = data["id"] as? String ?? UUID().uuidString

                        let calories = data["calories"] as? Double
                        let proteinsGrams = data["proteinsGrams"] as? Double
                        let carbs = data["carbs"] as? Double
                        let fats = data["fats"] as? Double
                        let ingredientQuantities = data["ingredientQuantities"] as? [String: Int]

                        return Meal(
                            id: id,
                            mealId: mealId,
                            proteins: proteins,
                            starchies: starchies,
                            vegetables: vegetables,
                            imageURL: imageURL,
                            name: name,
                            goal: goal,
                            cuisine: cuisine,
                            season: season,
                            calories: calories,
                            proteinsGrams: proteinsGrams,
                            carbs: carbs,
                            fats: fats,
                            ingredientQuantities: ingredientQuantities
                        )
                    }

                    self.hasLoadedMeals = true
                    print("✅ Nombre total de repas chargés : \(self.meals.count)")
                }
            }
    }

    func forceRefresh() {
        hasLoadedMeals = false
        fetchGeneratedMeals()
    }
}
