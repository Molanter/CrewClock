//
//  FAQModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import SwiftUI
import FirebaseFirestore

struct FAQ: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var question: String
    var answer: String
    var tags: [String]
    var order: Int
    var updatedAt: Date?
}
