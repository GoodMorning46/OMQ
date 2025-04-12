import Foundation
import UIKit
import SwiftUI

struct Meal: Identifiable, Codable {
    let id: String  // Toujours nécessaire pour SwiftUI
    var mealId: Int
    var proteins: [String]
    var starchies: [String]
    var vegetables: [String]
    var imageURL: String?

    // ✅ Autres champs
    var name: String         // Nom généré par l'IA
    var goal: String         // Ex: "🏡 Quotidien"
    var cuisine: String      // Ex: "🍕 Italienne"
    var season: String       // Ex: "☀️ Été"

    init(
        id: String = UUID().uuidString,
        mealId: Int,
        proteins: [String] = [],
        starchies: [String] = [],
        vegetables: [String] = [],
        imageURL: String? = nil,
        name: String = "",
        goal: String = "🏡 Quotidien",
        cuisine: String = "🏷️ Standard",
        season: String = "⛅️ Toute saison"
    ) {
        self.id = id
        self.mealId = mealId
        self.proteins = proteins
        self.starchies = starchies
        self.vegetables = vegetables
        self.imageURL = imageURL
        self.name = name
        self.goal = goal
        self.cuisine = cuisine
        self.season = season
    }

    static func fromFirestore(document: [String: Any]) -> Meal? {
        guard
            let mealId = document["mealId"] as? Int,
            let proteins = document["proteins"] as? [String],
            let starchies = document["starchies"] as? [String],
            let vegetables = document["vegetables"] as? [String],
            let name = document["name"] as? String,
            let goal = document["goal"] as? String,
            let cuisine = document["cuisine"] as? String,
            let season = document["season"] as? String
        else {
            return nil
        }

        return Meal(
            id: document["id"] as? String ?? UUID().uuidString,
            mealId: mealId,
            proteins: proteins,
            starchies: starchies,
            vegetables: vegetables,
            imageURL: document["imageURL"] as? String,
            name: name,
            goal: goal,
            cuisine: cuisine,
            season: season
        )
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "mealId": mealId,
            "proteins": proteins,
            "starchies": starchies,
            "vegetables": vegetables,
            "imageURL": imageURL ?? "",
            "name": name,
            "goal": goal,
            "cuisine": cuisine,
            "season": season
        ]
    }
}
