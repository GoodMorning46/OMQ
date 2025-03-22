import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @Binding var meals: [Meal]
    var onDismiss: () -> Void
    @State private var meal = Meal(name: "", description: "")
    @State private var isGeneratingImage = false
    @Environment(\.dismiss) private var dismiss
    private let imageGenerator = ImageGenerator()

    var isFormValid: Bool {
        !meal.name.isEmpty && !(meal.description?.isEmpty ?? true)
    }

    var body: some View {
        VStack {
            Text("Ajouter un repas")
                .font(.title)
                .padding()

            Form {
                Section(header: Text("Nom du repas")) {
                    TextField("Entrez le nom", text: $meal.name)
                }

                Section(header: Text("Description des ingrédients")) {
                    ZStack(alignment: .topLeading) {
                        if meal.description?.isEmpty ?? true {
                            Text("Entrez les ingrédients")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: Binding(
                            get: { meal.description ?? "" },
                            set: { meal.description = $0 }
                        ))
                        .frame(height: 100)
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
        let mealName = meal.name
        let ingredients = meal.description ?? ""

        imageGenerator.generateImage(for: mealName, ingredients: ingredients) { urlString in
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
                            resetForm()
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

    private func resetForm() {
        meal = Meal(name: "", description: "")
    }
}

#Preview {
    ContentView(meals: .constant([]), onDismiss: {})
}
