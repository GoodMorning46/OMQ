import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @Binding var meals: [Meal]
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let imageGenerator = ImageGenerator()
    
    private let nameGenerator = NameGenerator()
    @State private var generatedName = ""

    // Champs utilisateur
    @State private var mealId = Int.random(in: 1000...9999)
    @State private var protein = ""
    @State private var starchy = ""
    @State private var vegetable = ""
    @State private var goal = "🏡 Quotidien"
    @State private var cuisine = "🏷️ Standard"
    @State private var season = "⛅️ Toute saison"
    @State private var isGeneratingImage = false

    let goals = ["🏡 Quotidien", "🥗 Perte de poids", "💪 Prise de masse", "👦 Enfant"]
    let cuisines = ["🏷️ Standard", "🍕 Italienne", "🍜 Asiatique", "🥘 Orientale", "🌭 Américaine", "🥖 Française", "🌮 Mexicaine"]
    let seasons = ["⛅️ Toute saison", "❄️ Hiver", "☀️️ Été"]

    var isFormValid: Bool {
        !protein.isEmpty && !starchy.isEmpty && !vegetable.isEmpty
    }

    var body: some View {
        VStack {
            Text("Ajouter un repas")
                .font(.title)
                .padding()

            Form {
                Section(header: Text("Protéine")) {
                    TextField("Ex: Poulet", text: $protein)
                }

                Section(header: Text("Féculent")) {
                    TextField("Ex: Riz", text: $starchy)
                }

                Section(header: Text("Légume")) {
                    TextField("Ex: Brocoli", text: $vegetable)
                }

                Section(header: Text("Objectif")) {
                    Picker("Objectif", selection: $goal) {
                        ForEach(goals, id: \.self) { Text($0) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Type de cuisine")) {
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(cuisines, id: \.self) { Text($0) }
                    }
                }

                Section(header: Text("Saison")) {
                    Picker("Saison", selection: $season) {
                        ForEach(seasons, id: \.self) { Text($0) }
                    }
                }

                Section(header: Text("Image")) {
                    if isGeneratingImage {
                        ProgressView()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("L'image sera générée automatiquement.")
                            .foregroundColor(.gray)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .cornerRadius(20)

            Button(action: {
                generateImageAndUpload()
            }) {
                HStack {
                    if isGeneratingImage {
                        ProgressView()
                    }
                    Text("Ajouter")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 20)
            .disabled(!isFormValid || isGeneratingImage)
        }
        .padding(20)
        .navigationBarItems(leading: Button("Annuler") {
            dismiss()
        })
    }

    private func generateImageAndUpload() {
        isGeneratingImage = true

        nameGenerator.generateName(
            protein: protein,
            starchy: starchy,
            vegetable: vegetable,
            goal: goal
        ) { generated in
            DispatchQueue.main.async {
                self.generatedName = generated ?? "Plat sans nom"
                print("🍽️ Nom généré : \(self.generatedName)")

                let meal = Meal(
                    mealId: mealId,
                    name: self.generatedName,
                    protein: protein,
                    starchy: starchy,
                    vegetable: vegetable,
                    imageURL: nil,
                    goal: goal,
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
