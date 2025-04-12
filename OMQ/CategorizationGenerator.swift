import Foundation

class CategorizationGenerator {
    static func categorizeMeal(
        proteins: [String],
        starchies: [String],
        vegetables: [String],
        completion: @escaping (String?) -> Void
    ) {
        let proteinList = proteins.joined(separator: ", ")
        let starchyList = starchies.joined(separator: ", ")
        let vegetableList = vegetables.joined(separator: ", ")

        let prompt = """
        Voici un repas composé des ingrédients suivants :
        - Protéines : \(proteinList)
        - Féculents : \(starchyList)
        - Légumes : \(vegetableList)

        Catégorise ce repas parmi l’un des objectifs suivants :
        🏡 Quotidien, 🥗 Perte de poids, 💪 Prise de masse, 👦 Enfant

        Réponds uniquement par l’un des emojis ci-dessus. Aucune explication.
        """

        print("📤 Envoi du prompt de catégorisation à OpenAI : \n\(prompt)")

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
                ["role": "system", "content": "Tu es un expert en nutrition et catégorisation de repas."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 10,
            "temperature": 0.7
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
                let decoded = try JSONDecoder().decode(CategorizationResponse.self, from: data)
                let message = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Objectif généré : \(message ?? "aucun")")
                completion(message)
            } catch {
                print("❌ Erreur de décodage JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

struct CategorizationResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
