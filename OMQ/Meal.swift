import Foundation
import UIKit
import SwiftUI

struct Meal: Identifiable, Codable {
    let id: String  // Toujours nécessaire pour SwiftUI
    var mealId: Int
    var name: String       // ✅ Nouveau champ
    var protein: String
    var starchy: String
    var vegetable: String
    var imageURL: String?

    // ✅ Champs supplémentaires
    var goal: String        // Ex: "🏡 Quotidien"
    var cuisine: String     // Ex: "🍕 Italienne"
    var season: String      // Ex: "☀️ Été"

    init(
        id: String = UUID().uuidString,
        mealId: Int,
        name: String = "",
        protein: String,
        starchy: String,
        vegetable: String,
        imageURL: String? = nil,
        goal: String = "🏡 Quotidien",
        cuisine: String = "🏷️ Standard",
        season: String = "⛅️ Toute saison"
    ) {
        self.id = id
        self.mealId = mealId
        self.name = name
        self.protein = protein
        self.starchy = starchy
        self.vegetable = vegetable
        self.imageURL = imageURL
        self.goal = goal
        self.cuisine = cuisine
        self.season = season
    }

    static func fromFirestore(document: [String: Any]) -> Meal? {
        guard
            let mealId = document["mealId"] as? Int,
            let name = document["name"] as? String,
            let protein = document["protein"] as? String,
            let starchy = document["starchy"] as? String,
            let vegetable = document["vegetable"] as? String,
            let goal = document["goal"] as? String,
            let cuisine = document["cuisine"] as? String,
            let season = document["season"] as? String
        else {
            return nil
        }

        return Meal(
            id: document["id"] as? String ?? UUID().uuidString,
            mealId: mealId,
            name: name,
            protein: protein,
            starchy: starchy,
            vegetable: vegetable,
            imageURL: document["imageURL"] as? String,
            goal: goal,
            cuisine: cuisine,
            season: season
        )
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "mealId": mealId,
            "name": name,
            "protein": protein,
            "starchy": starchy,
            "vegetable": vegetable,
            "imageURL": imageURL ?? "",
            "goal": goal,
            "cuisine": cuisine,
            "season": season
        ]
    }
}
