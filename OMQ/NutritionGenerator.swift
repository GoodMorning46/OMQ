import Foundation

struct MacronutrientInfo: Codable {
    let calories: Double
    let proteins: Double
    let carbs: Double
    let fats: Double
    let ingredientQuantities: [String: Int]
}

class NutritionGenerator {
    static func generateNutrition(
        proteins: [String],
        starchies: [String],
        vegetables: [String],
        completion: @escaping (MacronutrientInfo?) -> Void
    ) {
        let allIngredients = proteins + starchies + vegetables
        let ingredientsList = allIngredients.joined(separator: ", ")

        let prompt = """
        Voici un repas composé des ingrédients suivants :
        \(ingredientsList).

        Pour un repas adulte standard, donne une estimation réaliste des macronutriments suivants :
        - Calories totales (kcal)
        - Protéines (g)
        - Glucides (g)
        - Lipides (g)

        Pour chaque ingrédient, donne également une quantité standard en grammes.

        Réponds uniquement dans ce format JSON :
        {
          "calories": nombre,
          "proteins": nombre,
          "carbs": nombre,
          "fats": nombre,
          "ingredientQuantities": {
            "nom_ingredient_1": nombre,
            "nom_ingredient_2": nombre
          }
        }
        """

        print("📤 Envoi du prompt nutrition à OpenAI :\n\(prompt)")

        guard let apiKey = Secrets.openAIKey else {
            print("❌ Clé API OpenAI manquante.")
            completion(nil)
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("❌ URL invalide.")
            completion(nil)
            return
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "Tu es un nutritionniste expert en repas maison."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur OpenAI : \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Aucune donnée reçue.")
                completion(nil)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(NutritionResponse.self, from: data)
                let message = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)

                guard let message else {
                    print("❌ Aucun contenu dans la réponse.")
                    completion(nil)
                    return
                }

                print("📥 Réponse brute : \(message)")

                // Nettoyage du contenu si entouré de ```
                let cleaned = message
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
                    let jsonString = String(cleaned[start...end])
                    let jsonData = Data(jsonString.utf8)
                    let nutritionInfo = try JSONDecoder().decode(MacronutrientInfo.self, from: jsonData)
                    completion(nutritionInfo)
                } else {
                    print("❌ Format JSON non détecté.")
                    completion(nil)
                }
            } catch {
                print("❌ Erreur de décodage JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

// ✅ Structs renommées pour éviter les conflits
private struct NutritionResponse: Codable {
    let choices: [NutritionChoice]
}

private struct NutritionChoice: Codable {
    let message: NutritionMessage
}

private struct NutritionMessage: Codable {
    let content: String
}
