import Foundation
import UIKit
import SwiftUI

struct Meal: Identifiable, Codable {
    let id: String
    var mealId: Int
    var proteins: [String]
    var starchies: [String]
    var vegetables: [String]
    var imageURL: String?

    // ✅ Autres champs
    var name: String
    var goal: String
    var cuisine: String
    var season: String

    // ✅ Champs nutritionnels
    var calories: Double?
    var proteinsGrams: Double?
    var carbs: Double?
    var fats: Double?

    // ✅ Quantités par ingrédient
    var ingredientQuantities: [String: Int]?

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
        season: String = "⛅️ Toute saison",
        calories: Double? = nil,
        proteinsGrams: Double? = nil,
        carbs: Double? = nil,
        fats: Double? = nil,
        ingredientQuantities: [String: Int]? = nil
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
        self.calories = calories
        self.proteinsGrams = proteinsGrams
        self.carbs = carbs
        self.fats = fats
        self.ingredientQuantities = ingredientQuantities
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
            season: season,
            calories: document["calories"] as? Double,
            proteinsGrams: document["proteinsGrams"] as? Double,
            carbs: document["carbs"] as? Double,
            fats: document["fats"] as? Double,
            ingredientQuantities: document["ingredientQuantities"] as? [String: Int]
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
            "season": season,
            "calories": calories as Any,
            "proteinsGrams": proteinsGrams as Any,
            "carbs": carbs as Any,
            "fats": fats as Any,
            "ingredientQuantities": ingredientQuantities as Any
        ]
    }
}
