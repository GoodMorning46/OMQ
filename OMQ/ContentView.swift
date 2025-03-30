import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @Binding var meals: [Meal]
    var onDismiss: () -> Void

    @State private var meal = Meal(mealId: Int.random(in: 1000...9999), protein: "", starchy: "", vegetable: "", imageURL: nil)
    @State private var isGeneratingImage = false
    @Environment(\.dismiss) private var dismiss
    private let imageGenerator = ImageGenerator()

    var isFormValid: Bool {
        !meal.protein.isEmpty && !meal.starchy.isEmpty && !meal.vegetable.isEmpty
    }

    var body: some View {
        VStack {
            Text("Ajouter un repas")
                .font(.title)
                .padding()

            Form {
                Section(header: Text("Protéine")) {
                    TextField("Ex: Poulet", text: $meal.protein)
                }

                Section(header: Text("Féculent")) {
                    TextField("Ex: Riz", text: $meal.starchy)
                }

                Section(header: Text("Légume")) {
                    TextField("Ex: Brocoli", text: $meal.vegetable)
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
        meal = Meal(mealId: Int.random(in: 1000...9999), protein: "", starchy: "", vegetable: "", imageURL: nil)
    }
}

#Preview {
    ContentView(meals: .constant([]), onDismiss: {})
}
