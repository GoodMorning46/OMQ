import SwiftUI
import Firebase

struct MainView: View {
    @State private var meals: [Meal] = []
    @StateObject private var mealPlanner = MealPlanner()
    @State private var selectedTab: Int = 0
    @State private var showRegisterView = false

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                switch selectedTab {
                case 0:
                    MealListView(mealPlanner: mealPlanner)
                case 1:
                    PlannerView(mealPlanner: mealPlanner)
                case 2:
                    BuyView()
                case 3:
                    UserView()
                default:
                    MealListView(mealPlanner: mealPlanner)
                }

                // 🔒 Bouton "S'inscrire" commenté car utilisateur déjà connecté
                /*
                Button(action: {
                    showRegisterView = true
                }) {
                    Text("S'inscrire")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .sheet(isPresented: $showRegisterView) {
                    RegisterView()
                }
                .padding(.bottom, 20)
                */
                Spacer()
            }

            // 🧭 Menu flottant
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.bottom) 
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            TabBarButton(icon: "magnifyingglass", index: 0, selectedTab: $selectedTab) // 🍽️ Meals
            Spacer()
            TabBarButton(icon: "calendar", index: 1, selectedTab: $selectedTab) // 📅 Planner
            Spacer()
            TabBarButton(icon: "cart", index: 2, selectedTab: $selectedTab) // 🛒 Buy
            Spacer()
            TabBarButton(icon: "person.crop.circle", index: 3, selectedTab: $selectedTab) // 👤 User
        }
        .padding()
        .frame(width: 320, height: 80)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let index: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundColor(selectedTab == index ? .blue : .gray)
                .padding()
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
}
