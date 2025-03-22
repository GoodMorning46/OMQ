import SwiftUI
import Firebase
import FirebaseAuth

@main
struct OMQApp: App {
    @StateObject private var authManager = AuthManager.shared  // ✅ Gestion de l'authentification

    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configuré sans AppDelegate !")
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isUserLoggedIn {
                // ✅ Afficher `MainView` qui gère MealListView et d'autres écrans
                MainView()
                    .environmentObject(authManager)
            } else {
                // ✅ Afficher `RegisterView` si l'utilisateur n'est pas connecté
                RegisterView()
                    .environmentObject(authManager)
            }
        }
    }
}
