import Foundation

class NameGenerator {
    static func generateName(proteins: [String], starchies: [String], vegetables: [String], goal: String, completion: @escaping (String?) -> Void) {
        
        // ✅ Conversion des tableaux en texte lisible
            let proteinList = proteins.joined(separator: ", ")
            let starchyList = starchies.joined(separator: ", ")
            let vegetableList = vegetables.joined(separator: ", ")
        
        let prompt = """
        Propose un nom de repas simple, appétissant et mémorable (maximum 2 mots) pour un plat composé de : \(proteinList), \(starchyList), \(vegetableList). \
        L'objectif du repas est : \(goal). Le nom doit être compréhensible par tous, donner envie, et être facilement retenu.
        """

        print("📤 Envoi à OpenAI avec le prompt : \(prompt)")

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
                ["role": "system", "content": "Tu es un assistant culinaire expert en naming de plats."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 15,
            "temperature": 0.8
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur requête OpenAI : \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Pas de données reçues.")
                completion(nil)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                let message = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = message?.components(separatedBy: "\n").first ?? message
                print("✅ Nom généré : \(name ?? "aucun")")
                completion(name)
            } catch {
                print("❌ Erreur décodage JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
