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
                Text("On mange quoi ?")
                    .font(.custom("SFProText-Bold", size: 25))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showContentView = true
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
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
            
            // ➕ Bouton Ajouter un repas
            Button(action: {
                showContentView = true
            }) {
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
            }
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
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 20) {
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
                                        .frame(width: 170, height: 170)
                                        .clipped()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 170, height: 170)
                                        .foregroundColor(.gray)
                                case .empty:
                                    ProgressView()
                                        .frame(width: 170, height: 170)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170, height: 170)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(meal.name)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(width: 170, height: 200)
                .background(Color.white)
                .cornerRadius(12)
                .clipped()
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
