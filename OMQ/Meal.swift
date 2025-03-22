//
//  Meal.swift
//  OMQ
//
//  Created by Benjamin Lanery on 29/12/2024.
//

import Foundation
import UIKit
import SwiftUI

struct Meal: Identifiable, Codable {
    let id: String
    var name: String
    var imageURL: String?
    var description: String?

    init(id: String = UUID().uuidString, name: String, imageURL: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.description = description
    }

    // 🔥 Fonction pour transformer un document Firestore en `Meal`
    static func fromFirestore(document: [String: Any]) -> Meal? {
        guard let name = document["name"] as? String else { return nil }
        return Meal(
            id: document["id"] as? String ?? UUID().uuidString,
            name: name,
            imageURL: document["imageURL"] as? String,
            description: document["description"] as? String
        )
    }
}
