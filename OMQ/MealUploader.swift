import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class MealUploader {
    static func uploadMeal(_ meal: Meal, imageURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté."])))
            return
        }

        let storageRef = Storage.storage().reference()
        let imageName = UUID().uuidString + ".png"
        let imageRef = storageRef.child("mealImages/\(imageName)")

        // 🔁 Upload de l’image
        imageRef.putFile(from: imageURL, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Erreur d'upload : \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Erreur récupération URL : \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "StorageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL de téléchargement introuvable."])))
                    return
                }

                // ✅ Mise à jour du modèle avec l'URL d’image
                var updatedMeal = meal
                updatedMeal.imageURL = downloadURL.absoluteString

                saveMealToFirestore(meal: updatedMeal, userId: userId, completion: completion)
            }
        }
    }

    private static func saveMealToFirestore(meal: Meal, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        var mealData = meal.toFirestoreData()
        mealData["createdAt"] = Timestamp(date: Date()) // Ajout de la date

        db.collection("users").document(userId).collection("generatedMeals").addDocument(data: mealData) { error in
            if let error = error {
                print("❌ Firestore error : \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Repas enregistré avec tous les champs.")
                completion(.success(()))
            }
        }
    }
}
