import SwiftUI
import Firebase

struct MainView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home, planner, cart, profile
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 🧩 Vue principale selon l'onglet sélectionné
            Group {
                switch selectedTab {
                case .home: MealListView(mealPlanner: MealPlanner())
                case .planner: PlannerView(mealPlanner: MealPlanner())
                case .cart: Text("Courses")
                case .profile: UserView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)

            // 🧭 Custom Tab Bar
            HStack {
                tabItem(icon: "fork.knife", label: "Repas", tab: .home)
                tabItem(icon: "calendar", label: "Planning", tab: .planner)
                tabItem(icon: "cart", label: "Liste", tab: .cart)
                tabItem(icon: "sparkles", label: "Découvrir", tab: .profile)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.appBackground)
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.bottom, 20)
            .padding(.horizontal, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - 🧩 Tab Item
    func tabItem(icon: String, label: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .blue : .gray)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
}
