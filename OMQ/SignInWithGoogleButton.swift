import SwiftUI
import GoogleSignIn
import FirebaseAuth

struct SignInWithGoogleButton: View {
    var body: some View {
        Button(action: handleGoogleSignIn) {
            HStack {
                Image(systemName: "globe")
                Text("Se connecter avec Google")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }

    func handleGoogleSignIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            print("❌ Impossible d'obtenir rootViewController")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("❌ Erreur Google Sign In : \(error.localizedDescription)")
                return
            }

            guard
                let user = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                print("❌ Informations utilisateur Google manquantes")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("❌ Erreur Firebase Sign In : \(error.localizedDescription)")
                } else {
                    print("✅ Connexion Firebase avec Google réussie !")
                }
            }
        }
    }
}
