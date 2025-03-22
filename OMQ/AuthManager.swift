import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isUserLoggedIn: Bool = false  // 🔥 Suivi de l'état de connexion

    private init() {
        self.isUserLoggedIn = Auth.auth().currentUser != nil
    }

    // 🔹 Vérifier l'utilisateur actuellement connecté
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }

    // 🔹 Inscription avec ajout dans Firestore
    func registerUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                DispatchQueue.main.async {
                    self.isUserLoggedIn = true  // ✅ Mise à jour après connexion
                }

                // 🔥 Ajouter l'utilisateur dans Firestore
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "email": email,
                    "createdAt": Timestamp(date: Date())
                ]

                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("❌ Erreur lors de l'ajout de l'utilisateur dans Firestore : \(error.localizedDescription)")
                    } else {
                        print("✅ Utilisateur ajouté dans Firestore avec succès !")
                    }
                }

                completion(.success(user))
            }
        }
    }

    // 🔹 Connexion
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                DispatchQueue.main.async {
                    self.isUserLoggedIn = true  // ✅ Mise à jour après connexion
                }
                completion(.success(user))
            }
        }
    }

    // 🔹 Déconnexion
    func logoutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isUserLoggedIn = false  // ✅ Mise à jour après déconnexion
            }
            completion(.success(()))
        } catch let signOutError {
            completion(.failure(signOutError))
        }
    }
}
