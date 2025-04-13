import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct MealListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MealViewModel()
    @State private var selectedMeal: Meal? = nil
    @State private var navigateToMealDetail = false
    @State private var showPicker = false
    @State private var showContentView = false
    @State private var searchText: String = ""

    // Filtres sélectionnés
    @State private var selectedGoal: String = ""
    @State private var selectedCuisine: String = ""
    @State private var selectedSeason: String = ""
    @State private var showFilterSheet = false

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
            .background(Color.appBackground)
            .onAppear {
                if viewModel.meals.isEmpty {
                    viewModel.fetchGeneratedMeals()
                }
            }
            .sheet(isPresented: $showContentView) {
                ContentView(meals: $viewModel.meals, onDismiss: {
                    viewModel.forceRefresh()
                })
                .presentationDetents([.height(600)]) // ← taille personnalisée
                .presentationDragIndicator(.visible) // ← poignée visible pour fermer
            }
            .sheet(isPresented: $showFilterSheet) {
                MealFilterView(
                    selectedGoal: $selectedGoal,
                    selectedCuisine: $selectedCuisine,
                    selectedSeason: $selectedSeason,
                    isPresented: $showFilterSheet
                )
                .presentationDetents([.height(650)])
                .presentationDragIndicator(.hidden)
            }
            .background(
                NavigationLink(
                            destination: Group {
                                if let meal = selectedMeal {
                                    MealDetailView(meal: meal)
                                } else {
                                    EmptyView()
                                }
                            },
                            isActive: $navigateToMealDetail,
                            label: { EmptyView() }
                        )
                .hidden()
            )
        }
    }

    // MARK: - Header
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

            Spacer().frame(height: 4)

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

            HStack {
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

                Spacer()

                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(10)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Liste des repas
    private var mealsGridView: some View {
        let filteredMeals = viewModel.meals.filter { meal in
            let matchesGoal = selectedGoal.isEmpty || meal.goal == selectedGoal
            let matchesCuisine = selectedCuisine.isEmpty || meal.cuisine == selectedCuisine
            let matchesSeason = selectedSeason.isEmpty || meal.season == selectedSeason

            // 🔍 Filtrage par recherche texte (nom ou ingrédients)
            let lowercasedSearch = searchText.lowercased()
            let searchIsEmpty = lowercasedSearch.trimmingCharacters(in: .whitespacesAndNewlines).count < 3

            let matchesSearch = searchIsEmpty ||
                meal.name.lowercased().contains(lowercasedSearch) ||
                meal.proteins.contains(where: { $0.lowercased().contains(lowercasedSearch) }) ||
                meal.starchies.contains(where: { $0.lowercased().contains(lowercasedSearch) }) ||
                meal.vegetables.contains(where: { $0.lowercased().contains(lowercasedSearch) })

            return matchesGoal && matchesCuisine && matchesSeason && matchesSearch
        }

        return VStack {
            if filteredMeals.isEmpty {
                Text("Aucun repas enregistré")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredMeals) { meal in
                            MealCardView(meal: meal) {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedMeal = meal
                                navigateToMealDetail = true
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
            ZStack(alignment: .bottomLeading) {
                Button(action: onTap) {
                    if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
                        ZStack {
                            WebImage(url: url)
                                .resizable()
                                .indicator(.activity)
                                .transition(.fade(duration: 0.3))
                                .scaledToFill()
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }

                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .clipped()
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 6) {
                    if !meal.name.isEmpty {
                        Text(meal.name.capitalized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }

                    HStack(spacing: 6) {
                        let allTags: [(String, Color)] =
                            meal.proteins.map { ($0, .blue) } +
                            meal.starchies.map { ($0, .orange) } +
                            meal.vegetables.map { ($0, .green) }

                        let visibleTags = allTags.prefix(3)
                        let hasMore = allTags.count > 3

                        ForEach(visibleTags, id: \ .0) { (text, color) in
                            TagLabel(text: text, tint: .white, blur: color.opacity(0.6))
                        }

                        if hasMore {
                            TagLabel(text: "⋯", tint: .white, blur: Color.gray.opacity(0.4))
                        }
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
            }
            .background(Color.white)
            .cornerRadius(16)
            .clipped()
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 4)
        }
    }

    struct TagLabel: View {
        let text: String
        var tint: Color = .white
        var blur: Color = Color.black.opacity(0.35)

        var body: some View {
            Text(text.capitalized)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .background(
                    blur
                        .blur(radius: 10)
                        .clipShape(Capsule())
                )
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
        }
    }

    struct MealTag: View {
        var text: String
        var color: Color
        var textColor: Color

        var body: some View {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(15)
        }
    }
}

struct MealListView_PreviewContainer: View {
    var body: some View {
        MealListView(mealPlanner: MealPlanner())
    }
}

#Preview {
    MealListView_PreviewContainer()
}
