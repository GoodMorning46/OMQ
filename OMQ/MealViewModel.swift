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
                        let meal = Meal.fromFirestore(document: doc.data())
                        if meal == nil {
                            print("⚠️ Un document a été ignoré à cause de données incomplètes")
                        }
                        return meal
                    }

                    self.hasLoadedMeals = true
                    print("✅ Nombre total de repas chargés : \(self.meals.count)")

                    for meal in self.meals {
                        print("🥩 \(meal.protein), 🥔 \(meal.starchy), 🥦 \(meal.vegetable), 🎯 \(meal.goal), 🍽️ \(meal.cuisine), 🌦️ \(meal.season)")
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
