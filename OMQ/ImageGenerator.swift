import Foundation

class ImageGenerator {
    func generateImage(for mealName: String, ingredients: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        Un plat appétissant servi sur une assiette rustique en céramique. Le plat est composé de '\(mealName)'. L’assiette repose sur une table en bois chaleureuse, accompagnée d’un verre de vin et d’herbes fraîches pour une touche gastronomique. La lumière douce et naturelle met en valeur les textures et les couleurs du plat.
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
                   "model": "dall-e-3",       // ✅ Forcé
                   "prompt": prompt,
                   "n": 1,
                   "size": "1024x1024"        // ✅ Plus grande taille
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
