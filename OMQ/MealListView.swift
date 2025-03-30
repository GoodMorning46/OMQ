import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MealListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MealViewModel()
    @State private var selectedMeal: Meal? = nil
    @State private var showPicker = false
    @State private var showContentView = false
    @State private var searchText: String = ""

    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var mealPlanner: MealPlanner

    let pickerCategories = ["Déj", "Dîner"]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                    .padding(.top, 20)

                if viewModel.isLoadingMeals {
                    loadingView
                } else {
                    mealsGridView
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color.appBackground) // ✅ Fond personnalisé ici
            .onAppear {
                viewModel.fetchGeneratedMeals()
            }
            .sheet(isPresented: $showContentView) {
                ContentView(meals: $viewModel.meals, onDismiss: {
                    viewModel.fetchGeneratedMeals()
                })
            }
            .fullScreenCover(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
    }

    // MARK: - Header (Titre + Boutons + Barre de recherche)
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On mange\nquoi ?")
                    .font(.custom("SFProText-Bold", size: 30))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink(destination: UserView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
            }

            // Ajout d’un espacement
            Spacer().frame(height: 4) // 👈 tu peux ajuster cette valeur

            // 🔍 Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Rechercher un plat...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
            

            // ➕ Bouton Ajouter un repas
            Button(action: {
                showContentView = true
            }) {
                Text("Ajouter un repas")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
            }
            .padding(.bottom, 12) // ou Spacer(minLength: 12)
        }
    }

    // MARK: - Liste des repas (Grille)
    private var mealsGridView: some View {
        VStack {
            if viewModel.meals.isEmpty {
                Text("Aucun repas enregistré")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.meals) { meal in
                            MealCardView(meal: meal) {
                                selectedMeal = meal
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Vue de chargement
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Chargement des repas...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }

    // MARK: - MealCardView
    struct MealCardView: View {
        let meal: Meal
        let onTap: () -> Void

        var body: some View {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Button(action: onTap) {
                        if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.gray)
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.gray)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(meal.protein), \(meal.starchy), \(meal.vegetable)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 12)
                }
                .background(Color.white)
                .cornerRadius(12)
                .clipped()
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
                .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Preview
struct MealListView_PreviewContainer: View {
    var body: some View {
        MealListView(mealPlanner: MealPlanner())
    }
}

#Preview {
    MealListView_PreviewContainer()
}
