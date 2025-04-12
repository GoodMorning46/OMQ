import SwiftUI

struct MealFilterView: View {
    // Filtres sélectionnés
    @Binding var selectedGoal: String
    @Binding var selectedCuisine: String
    @Binding var selectedSeason: String
    @Binding var isPresented: Bool

    let goals = ["🏡 Quotidien", "🥗 Perte de poids", "💪 Prise de masse", "👦 Enfant"]

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Capsule proche du haut
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            FilterSection(title: "Objectif", options: goals, selected: $selectedGoal)


            // ✅ ESPACE AJOUTÉ ICI
            Spacer(minLength: 16)

            HStack(spacing: 16) {
                Button("Réinitialiser") {
                    selectedGoal = ""
                    selectedCuisine = ""
                    selectedSeason = ""
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.black)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                Button("Valider") {
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom)
        .background(Color.white)
        .cornerRadius(30)
        .padding(.bottom, 8)
    }
}

struct FilterSection: View {
    let title: String
    let options: [String]
    @Binding var selected: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if selected == option {
                            selected = "" // ✅ Désélection
                        } else {
                            selected = option
                        }
                    }) {
                        Text(option)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 110, height: 48) // ✅ Taille plus grande
                            .background(
                                selected == option ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1)
                            )
                            .foregroundColor(selected == option ? .blue : .gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selected == option ? Color.blue : Color.gray.opacity(0.3), lineWidth: selected == option ? 1.6 : 1)
                            )
                            .cornerRadius(14)
                    }
                }
            }
        }
    }
}
