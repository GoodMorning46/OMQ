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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 4)
                            .scaleEffect(1.1)
                            .offset(y: -4)
                            .transition(.scale)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .blue : .gray)
                        .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                        .offset(y: selectedTab == tab ? -4 : 0)
                }

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
