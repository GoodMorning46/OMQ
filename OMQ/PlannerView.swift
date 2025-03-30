import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class MealPlanner: ObservableObject {
    @Published var plans: [String: [String: String]] = [:] // [Jour: [Catégorie: Nom du repas]]
    
    private let db = Firestore.firestore()
    
    /// 🔥 Charge les repas planifiés de l'utilisateur depuis Firestore
    func loadPlannedMeals(for userId: String) {
        db.collection("users").document(userId).collection("plannedMeals").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Erreur lors de la récupération des repas planifiés: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.plans.removeAll()
                
                for document in documents {
                    let data = document.data()
                    let mealName = data["name"] as? String ?? "—"
                    let category = data["category"] as? String ?? "Déj"
                    let date = data["date"] as? String ?? ""
                    
                    if !date.isEmpty {
                        if self.plans[date] == nil {
                            self.plans[date] = [:]
                        }
                        self.plans[date]?[category] = mealName
                    }
                }
                
                print("✅ Repas planifiés chargés avec succès !")
            }
        }
    }
    
    /// 🔥 Ajoute un repas planifié dans Firestore
    func planMealToFirestore(meal: Meal, category: String, date: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Erreur: utilisateur non authentifié.")
            return
        }
        
        let mealData: [String: Any] = [
            "protein": meal.protein,
            "starchy": meal.starchy,
            "vegetable": meal.vegetable,
            "category": category,
            "date": date,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).collection("plannedMeals").addDocument(data: mealData) { error in
            if let error = error {
                print("❌ Erreur lors de l'ajout du repas planifié: \(error.localizedDescription)")
            } else {
                print("✅ Repas planifié ajouté avec succès !")
            }
        }
    }
}

struct PlannerView: View {
    @ObservedObject var mealPlanner: MealPlanner

    // 🔥 Génère les 7 prochains jours dynamiquement
    private func getNextSevenDays() -> [String] {
        var days: [String] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "yyyy-MM-dd" // Stocké en format ISO pour Firestore

        for i in 0..<7 {
            if let futureDate = calendar.date(byAdding: .day, value: i, to: Date()) {
                let formattedDay = formatter.string(from: futureDate)
                days.append(formattedDay)
            }
        }
        return days
    }

    @State private var selectedDay: String = "" // Jour sélectionné
    private let categories = ["Déj", "Dîner"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 🔹 Titre
            Text("Planifier")
                .font(.custom("SFProText-Bold", size: 25))
                .padding(.top, 20)
                .padding(.horizontal, 20)

            // 🔹 Sélecteur de jours sous le titre
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(getNextSevenDays(), id: \.self) { jour in
                        Button(action: {
                            selectedDay = jour
                        }) {
                            Text(jour)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedDay == jour ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedDay == jour ? .white : .black)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // 🔹 Tableau des repas du jour sélectionné
            VStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    VStack(alignment: .leading) {
                        Text(category)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)

                        Text(mealPlanner.plans[selectedDay]?[category] ?? "—")
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal, 10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)

            Spacer()
        }
        .onAppear {
            if selectedDay.isEmpty, let firstDay = getNextSevenDays().first {
                selectedDay = firstDay
            }
            
            if let userId = Auth.auth().currentUser?.uid {
                mealPlanner.loadPlannedMeals(for: userId)
            }
        }
    }
}

// MARK: - Preview
struct PlannerView_PreviewContainer: View {
    var body: some View {
        PlannerView(mealPlanner: MealPlanner())
    }
}

#Preview {
    PlannerView_PreviewContainer()
}
