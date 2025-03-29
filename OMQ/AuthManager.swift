import FirebaseAuth
import FirebaseFirestore
import Firebase
import GoogleSignIn
import GoogleSignInSwift
import Combine
import UIKit

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isUserLoggedIn: Bool = false

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
                    self.isUserLoggedIn = true
                }

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

    // 🔹 Connexion avec email/mot de passe
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                DispatchQueue.main.async {
                    self.isUserLoggedIn = true
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
                self.isUserLoggedIn = false
            }
            completion(.success(()))
        } catch let signOutError {
            completion(.failure(signOutError))
        }
    }

    // 🔹 Connexion avec Google
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "GoogleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Client ID non trouvé"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "GoogleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aucune fenêtre disponible"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: 2, userInfo: [NSLocalizedDescriptionKey: "ID token introuvable"])
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)

        DispatchQueue.main.async {
            self.isUserLoggedIn = true
        }

        // ✅ Ajouter dans Firestore si ce n’est pas encore fait
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": authResult.user.email ?? "",
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("users").document(authResult.user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Erreur lors de l'ajout Google utilisateur dans Firestore : \(error.localizedDescription)")
            } else {
                print("✅ Utilisateur Google ajouté dans Firestore")
            }
        }
    }
}
