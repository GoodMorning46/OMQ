import SwiftUI
import FirebaseAuth
import GoogleSignInSwift

struct RegisterView: View {
    // MARK: - Variables d’état
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var isLoginMode = false

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack {
                Spacer(minLength: 20)

                // 📌 Titre principal
                Text(isLoginMode ? "Se connecter" : "Créer un compte")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 20)

                // 📩 Email
                CustomTextField(icon: "envelope", placeholder: "Email", text: $email)

                // 🔐 Mot de passe
                CustomSecureField(icon: "lock", placeholder: "Mot de passe", text: $password)

                // 🔐 Confirmation (si inscription)
                if !isLoginMode {
                    CustomSecureField(icon: "lock", placeholder: "Confirmer le mot de passe", text: $confirmPassword)
                }

                // 🔴 Message d’erreur
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 20)
                }

                // 📌 Bouton principal
                Button(action: handleAuth) {
                    HStack {
                        if isLoading { ProgressView().padding(.trailing, 5) }
                        Text(isLoginMode ? "Se connecter" : "S'inscrire")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .disabled(isLoading)
                .padding(.top, 10)

                // 🔐 Connexion avec Google
                Button(action: {
                    Task {
                        do {
                            try await AuthManager.shared.signInWithGoogle()
                        } catch {
                            print("❌ Erreur lors de la connexion avec Google : \(error.localizedDescription)")
                        }
                    }
                }) {
                    HStack {
                        Image("google-logo") // Le nom de l’image dans tes Assets
                                    .resizable()
                                    .frame(width: 20, height: 20)
                        Text("Continuer avec Google")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)

                // 🔄 Bascule
                Button(action: {
                    isLoginMode.toggle()
                    errorMessage = nil
                }) {
                    Text(isLoginMode ? "Pas encore de compte ? S'inscrire" : "Déjà un compte ? Se connecter")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(20)
        }
    }

    // MARK: - Auth
    private func handleAuth() {
        guard !email.isEmpty, !password.isEmpty, (isLoginMode || !confirmPassword.isEmpty) else {
            errorMessage = "Veuillez remplir tous les champs."
            return
        }

        if !isLoginMode, password != confirmPassword {
            errorMessage = "Les mots de passe ne correspondent pas."
            return
        }

        isLoading = true
        errorMessage = nil

        if isLoginMode {
            authManager.loginUser(email: email, password: password) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        print("✅ Connexion réussie")
                        authManager.isUserLoggedIn = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            authManager.registerUser(email: email, password: password) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success:
                        print("✅ Inscription réussie")
                        authManager.isUserLoggedIn = true
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Custom Fields
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
