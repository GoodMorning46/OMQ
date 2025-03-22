import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MealListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MealViewModel()
    @State private var selectedMeal: Meal?
    @State private var showPicker = false
    @State private var showContentView = false

    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var mealPlanner: MealPlanner

    let pickerCategories = ["Déj", "Dîner"]

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                    .padding(.top, 20)

                if viewModel.isLoadingMeals {
                    loadingView
                } else {
                    mealsGridView
                }

                Spacer() // 🔧 Ajout d'un Spacer pour pousser le contenu vers le haut
            }
            .padding(.horizontal, 20)
            .onAppear {
                print("🔥 MealListView s'affiche, lancement de fetchGeneratedMeals()")
                viewModel.fetchGeneratedMeals()
            }
            .sheet(isPresented: $showContentView) {
                ContentView(meals: $viewModel.meals, onDismiss: {
                    viewModel.fetchGeneratedMeals()
                })
            }
        }
    }

    // MARK: - Header (Titre + Boutons)
    private var headerView: some View {
        HStack {
            Text("MES PLATS")
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
                                showPicker = true
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
        let onPlan: () -> Void

        var body: some View {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
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

                    Text(meal.name)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(width: 170, height: 200)
                .background(Color.white)
                .cornerRadius(12)
                .clipped()

//                Button(action: onPlan) {
//                    Image(systemName: "calendar")
//                        .padding(8)
//                        .background(Color.orange)
//                        .foregroundColor(.white)
//                        .clipShape(Circle())
//                        .padding(6)
//                }
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
