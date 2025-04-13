import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UIKit

struct ContentView: View {
    @Binding var meals: [Meal]
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let imageGenerator = ImageGenerator()
    private let nameGenerator = NameGenerator()

    @State private var generatedName = ""

    // Champs utilisateur
    @State private var mealId = Int.random(in: 1000...9999)
    @State private var proteins: [String] = [""]
    @State private var starchies: [String] = [""]
    @State private var vegetables: [String] = [""]
    @State private var cuisine = "🏷️ Standard"
    @State private var season = "⛅️ Toute saison"
    @State private var isGeneratingImage = false

    // Focus pour déclencher vibration
    @FocusState private var focusedProteinIndex: Int?
    @FocusState private var focusedStarchyIndex: Int?
    @FocusState private var focusedVegetableIndex: Int?

    let cuisines = ["🏷️ Standard", "🍕 Italienne", "🍜 Asiatique", "🥘 Orientale", "🌭 Américaine", "🥖 Française", "🌮 Mexicaine"]
    let seasons = ["⛅️ Toute saison", "❄️ Hiver", "☀️️ Été"]

    var isFormValid: Bool {
        !proteins.filter { !$0.isEmpty }.isEmpty &&
        !starchies.filter { !$0.isEmpty }.isEmpty &&
        !vegetables.filter { !$0.isEmpty }.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("🧑‍🍳 Créer un repas")
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                    .padding(.bottom, 16)

                ingredientSection(title: "Protéines", items: $proteins, placeholder: "Ex: Poulet")
                ingredientSection(title: "Féculents", items: $starchies, placeholder: "Ex: Riz")
                ingredientSection(title: "Légumes", items: $vegetables, placeholder: "Ex: Brocoli")
                
                Spacer().frame(height: 40)

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    generateImageAndUpload()
                }) {
                    HStack {
                        if isGeneratingImage {
                            ProgressView()
                        }
                        Text("Ajouter le repas")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.orange : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isGeneratingImage)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.white)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .ignoresSafeArea(edges: .bottom)
        .navigationBarItems(leading: Button("Annuler") {
            dismiss()
        })
        // ✅ Vibration à l’apparition du clavier
        .onChange(of: focusedProteinIndex) { _ in vibrateOnFocus() }
        .onChange(of: focusedStarchyIndex) { _ in vibrateOnFocus() }
        .onChange(of: focusedVegetableIndex) { _ in vibrateOnFocus() }
    }

    // MARK: - Section d’ingrédients
    @ViewBuilder
    func ingredientSection(title: String, items: Binding<[String]>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Button(action: {
                    items.wrappedValue.append("")
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18, weight: .bold))
                }

                Spacer()
            }

            ForEach(Array(items.wrappedValue.enumerated()), id: \.offset) { index, value in
                HStack(spacing: 12) {
                    Text(emojiForIngredient(value))
                        .font(.system(size: 20))

                    TextField(placeholder, text: Binding(
                        get: { items.wrappedValue[index] },
                        set: { items.wrappedValue[index] = $0 }
                    ))
                    .focused(bindingFor(title: title), equals: index)
                    .padding(.horizontal, 12)
                    .frame(height: 64)
                    .frame(maxWidth: 280)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    if items.wrappedValue.count > 1 && index != 0 {
                        Button(action: {
                            var updated = items.wrappedValue
                            updated.remove(at: index)
                            items.wrappedValue = updated
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
        }
    }

    private func vibrateOnFocus() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func bindingFor(title: String) -> FocusState<Int?>.Binding {
        switch title {
        case "Protéines": return $focusedProteinIndex
        case "Féculents": return $focusedStarchyIndex
        case "Légumes": return $focusedVegetableIndex
        default: return $focusedProteinIndex
        }
    }

    func emojiForIngredient(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()

        let emojiMap: [String: [String]] = [
            "🥦": ["brocoli", "brocolis"],
            "🍗": ["poulet", "blanc de poulet", "dinde", "volaille", "aiguillettes"],
            "🥩": ["boeuf", "bœuf", "steak", "entrecôte", "rumsteck", "côte", "viande rouge"],
            "🐖": ["porc", "jambon", "lard", "bacon", "saucisse"],
            "🐑": ["agneau", "mouton", "côtelettes", "gigot"],
            "🐟": ["poisson", "saumon", "cabillaud", "thon", "truite", "sardine", "bar"],
            "🦐": ["crevette", "gambas", "crustacé", "homard", "langoustine"],
            "🥚": ["œuf", "oeuf", "omelette", "œufs"],
            "🍚": ["riz", "basmati", "thaï", "sushi", "complet"],
            "🥔": ["patate", "pomme de terre", "pommes de terre", "patates", "purée", "gratin dauphinois"],
            "🍝": ["pâtes", "spaghetti", "tagliatelle", "penne", "macaroni", "lasagnes", "pâte"],
            "🍞": ["pain", "baguette", "brioche", "toast"],
            "🌽": ["maïs", "mais", "épi", "popcorn"],
            "🥕": ["carotte", "carottes", "carotène"],
            "🍅": ["tomate", "tomates"],
            "🥬": ["salade", "laitue", "mesclun", "roquette"],
            "🥒": ["concombre", "cornichon"],
            "🧅": ["oignon", "échalote"],
            "🧄": ["ail"],
            "🫘": ["lentille", "lentilles", "pois chiches", "haricots", "flageolets", "fèves"],
            "🧀": ["fromage", "gruyère", "emmental", "mozzarella", "chèvre", "comté"],
            "🥖": ["baguette", "pain", "ficelle"],
            "🍎": ["pomme", "pommes"],
            "🍌": ["banane", "bananes"],
            "🍇": ["raisin", "raisins"],
            "🍓": ["fraise", "fraises"],
            "🍍": ["ananas"],
            "🍊": ["orange", "clémentine", "mandarine"],
            "🍋": ["citron", "citrons"],
            "🥭": ["mangue", "mangues"],
            "🥥": ["noix de coco", "coco"],
            "🍽️": []
        ]

        for (emoji, keywords) in emojiMap {
            if keywords.contains(where: lowercased.contains) {
                return emoji
            }
        }

        return "🍽️"
    }

    // MARK: - Upload & Image
    private func generateImageAndUpload() {
        isGeneratingImage = true

        CategorizationGenerator.categorizeMeal(
            proteins: proteins,
            starchies: starchies,
            vegetables: vegetables
        ) { detectedGoal in
            let finalGoal = detectedGoal ?? "🏡 Quotidien"

            NameGenerator.generateName(
                proteins: proteins,
                starchies: starchies,
                vegetables: vegetables,
                goal: finalGoal
            ) { name in
                guard let name = name else {
                    print("❌ Échec de la génération du nom")
                    isGeneratingImage = false
                    return
                }

                let meal = Meal(
                    mealId: mealId,
                    proteins: proteins,
                    starchies: starchies,
                    vegetables: vegetables,
                    imageURL: nil,
                    name: name,
                    goal: finalGoal,
                    cuisine: cuisine,
                    season: season
                )

                imageGenerator.generateImage(for: meal) { urlString in
                    guard let urlString = urlString, let url = URL(string: urlString) else {
                        print("❌ URL d'image invalide")
                        isGeneratingImage = false
                        return
                    }

                    downloadImage(from: url) { localURL in
                        guard let localURL = localURL else {
                            print("❌ Erreur : échec du téléchargement local")
                            isGeneratingImage = false
                            return
                        }

                        MealUploader.uploadMeal(meal, imageURL: localURL) { result in
                            DispatchQueue.main.async {
                                isGeneratingImage = false
                                switch result {
                                case .success():
                                    meals.append(meal)
                                    onDismiss()
                                    dismiss()
                                case .failure(let error):
                                    print("❌ Erreur lors de l'upload : \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func downloadImage(from remoteURL: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: remoteURL) { localURL, _, error in
            if let error = error {
                print("❌ Erreur de téléchargement : \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(localURL)
        }
        task.resume()
    }
}

#Preview {
    ContentView(meals: .constant([]), onDismiss: {})
}
