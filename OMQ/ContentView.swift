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
    @State private var proteins: [String] = [""]
    @State private var starchies: [String] = [""]
    @State private var vegetables: [String] = [""]
    @State private var goal = "🏡 Quotidien"
    @State private var cuisine = "🏷️ Standard"
    @State private var season = "⛅️ Toute saison"
    @State private var isGeneratingImage = false

    let goals = ["🏡 Quotidien", "🥗 Perte de poids", "💪 Prise de masse", "👦 Enfant"]
    let cuisines = ["🏷️ Standard", "🍕 Italienne", "🍜 Asiatique", "🥘 Orientale", "🌭 Américaine", "🥖 Française", "🌮 Mexicaine"]
    let seasons = ["⛅️ Toute saison", "❄️ Hiver", "☀️️ Été"]

    var isFormValid: Bool {
        !proteins.filter { !$0.isEmpty }.isEmpty &&
        !starchies.filter { !$0.isEmpty }.isEmpty &&
        !vegetables.filter { !$0.isEmpty }.isEmpty
    }

    var body: some View {
        VStack {
            Text("Ajouter un repas")
                .font(.title)
                .padding()

            Form {
                // Section Protéine
                Section(header:
                    HStack {
                        Text("Protéine")
                        Spacer()
                        Button(action: {
                            proteins.append("")
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                ) {
                    ForEach(proteins.indices, id: \.self) { index in
                        TextField("Ex: Poulet", text: Binding(
                            get: { proteins[index] },
                            set: { proteins[index] = $0 }
                        ))
                    }
                }

                // Section Féculent
                Section(header:
                    HStack {
                        Text("Féculent")
                        Spacer()
                        Button(action: {
                            starchies.append("")
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                ) {
                    ForEach(starchies.indices, id: \.self) { index in
                        TextField("Ex: Riz", text: Binding(
                            get: { starchies[index] },
                            set: { starchies[index] = $0 }
                        ))
                    }
                }

                // Section Légume
                Section(header:
                    HStack {
                        Text("Légume")
                        Spacer()
                        Button(action: {
                            vegetables.append("")
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                ) {
                    ForEach(vegetables.indices, id: \.self) { index in
                        TextField("Ex: Brocoli", text: Binding(
                            get: { vegetables[index] },
                            set: { vegetables[index] = $0 }
                        ))
                    }
                }

                // Section Objectif
                Section(header: Text("Objectif")) {
                    Picker("Objectif", selection: $goal) {
                        ForEach(goals, id: \.self) { Text($0) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Section Type de cuisine
                Section(header: Text("Type de cuisine")) {
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(cuisines, id: \.self) { Text($0) }
                    }
                }

                // Section Saison
                Section(header: Text("Saison")) {
                    Picker("Saison", selection: $season) {
                        ForEach(seasons, id: \.self) { Text($0) }
                    }
                }

                // Section Image
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

        let meal = Meal(
            mealId: mealId,
            proteins: proteins.filter { !$0.isEmpty },
            starchies: starchies.filter { !$0.isEmpty },
            vegetables: vegetables.filter { !$0.isEmpty },
            imageURL: nil,
            goal: goal,
            cuisine: cuisine,
            season: season
        )

        // Génération du nom du repas via IA
        NameGenerator.generateName(
            proteins: proteins,
            starchies: starchies,
            vegetables: vegetables,
            goal: goal
        ) { name in
            guard let name = name else {
                print("❌ Échec de la génération du nom")
                isGeneratingImage = false
                return
            }

            var namedMeal = meal
            namedMeal.name = name

            // Génération de l’image après le nom
            imageGenerator.generateImage(for: namedMeal) { urlString in
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

                    MealUploader.uploadMeal(namedMeal, imageURL: localURL) { result in
                        DispatchQueue.main.async {
                            isGeneratingImage = false
                            switch result {
                            case .success():
                                meals.append(namedMeal)
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
