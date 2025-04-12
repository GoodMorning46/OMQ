import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class MealPlanner: ObservableObject {
    // Tu pourras remettre la logique plus tard ici
}

struct PlannerView: View {
    @ObservedObject var mealPlanner: MealPlanner

    var body: some View {
        VStack {
            Spacer()

            Text("📅 Fonctionnalité à venir")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("Planning")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct PlannerView_PreviewContainer: View {
    var body: some View {
        PlannerView(mealPlanner: MealPlanner())
    }
}

#Preview {
    PlannerView_PreviewContainer()
}
