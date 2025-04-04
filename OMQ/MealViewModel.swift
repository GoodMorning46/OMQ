import Foundation
import FirebaseFirestore
import FirebaseAuth

class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var isLoadingMeals = true
    private var hasLoadedMeals = false // ✅ Cache mémoire

    func fetchGeneratedMeals() {
        print("🔥 fetchGeneratedMeals() est appelé")

        // ✅ Si les repas sont déjà en cache, on ne recharge pas
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

                    self.hasLoadedMeals = true // ✅ Marqué comme chargé
                    print("✅ Nombre total de repas chargés : \(self.meals.count)")

                    print("📸 Vérification des images des repas récupérés:")
                    for meal in self.meals {
                        print("Protéine: \(meal.protein), Féculent: \(meal.starchy), Légume: \(meal.vegetable), Image URL: \(meal.imageURL ?? "Aucune URL")")
                    }
                }
            }
    }

    // ✅ Pour forcer le rechargement depuis Firestore (ex: après ajout)
    func forceRefresh() {
        hasLoadedMeals = false
        fetchGeneratedMeals()
    }
}
