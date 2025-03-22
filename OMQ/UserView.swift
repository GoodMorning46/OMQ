import SwiftUI
import FirebaseAuth

struct UserView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Espace Utilisateur")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)

                Spacer()

                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    Text("Se déconnecter")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(isPresented: $showLogoutConfirmation) {
                Alert(
                    title: Text("Déconnexion"),
                    message: Text("Voulez-vous vraiment vous déconnecter ?"),
                    primaryButton: .destructive(Text("Oui")) {
                        authManager.logoutUser { _ in }
                    },
                    secondaryButton: .cancel(Text("Non"))
                )
            }
        }
    }
}

#Preview {
    UserView().environmentObject(AuthManager.shared)
}
