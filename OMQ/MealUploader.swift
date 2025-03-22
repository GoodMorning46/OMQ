import FirebaseStorage

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

        // 🔁 Upload du fichier local vers Firebase Storage
        imageRef.putFile(from: imageURL, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Erreur d'upload : \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // ✅ Récupérer l’URL de téléchargement publique
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

                // 🔥 Enregistrement du repas avec l’URL dans Firestore
                saveMealToFirestore(meal: meal, imageDownloadURL: downloadURL.absoluteString, userId: userId, completion: completion)
            }
        }
    }

    private static func saveMealToFirestore(meal: Meal, imageDownloadURL: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let mealData: [String: Any] = [
            "name": meal.name,
            "description": meal.description ?? "",
            "imageURL": imageDownloadURL,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("users").document(userId).collection("generatedMeals").addDocument(data: mealData) { error in
            if let error = error {
                print("❌ Firestore error : \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Repas enregistré avec succès dans Firestore.")
                completion(.success(()))
            }
        }
    }
}
