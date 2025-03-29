import SwiftUI
import Firebase
import FirebaseAuth


@main
struct OMQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authManager = AuthManager.shared  // ✅ Gestion de l'authentification

    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configuré sans AppDelegate !")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.appBackground.ignoresSafeArea() // ✅ Fond global partout

                if authManager.isUserLoggedIn {
                    MainView()
                        .environmentObject(authManager)
                } else {
                    RegisterView()
                        .environmentObject(authManager)
                }
            }
        }
    }
}
