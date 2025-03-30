import Foundation

class ImageGenerator {
    func generateImage(for meal: Meal, completion: @escaping (String?) -> Void) {
        let prompt = """
        Un plat joyeux et appétissant, présenté dans une assiette colorée en céramique sur une table en bois clair. Le repas est composé de \(meal.protein), accompagné de \(meal.starchy) et de \(meal.vegetable). La scène est baignée d’une lumière naturelle douce, avec des couleurs vives, des herbes fraîches, et un style convivial qui évoque un déjeuner d’été. L’ambiance est chaleureuse et inspirée des photos culinaires modernes sur Instagram.
        """
        print("📤 Envoi de la requête à OpenAI avec le prompt : \(prompt)")

        guard let apiKey = Secrets.openAIKey else {
            print("❌ Erreur : clé API OpenAI manquante.")
            completion(nil)
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            print("❌ Erreur : URL invalide.")
            completion(nil)
            return
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024"
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

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Erreur : réponse HTTP invalide.")
                completion(nil)
                return
            }

            print("📡 Statut de la réponse : \(httpResponse.statusCode)")

            guard let data = data else {
                print("❌ Erreur : pas de données reçues.")
                completion(nil)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)
                let imageURL = decoded.data.first?.url
                print("✅ Image générée avec succès : \(imageURL ?? "aucune URL")")
                completion(imageURL)
            } catch {
                print("❌ Erreur décodage JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

struct OpenAIImageResponse: Codable {
    let data: [OpenAIImageData]
}

struct OpenAIImageData: Codable {
    let url: String
}
