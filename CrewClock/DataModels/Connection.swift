//
//  Connection.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/14/25.
//

import SwiftUI
import FirebaseFirestore

enum ConnectionStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case rejected
    case blocked

    static func from(_ raw: String?) -> Self {
        Self(rawValue: raw ?? "") ?? .pending
    }

    // Ensure decoding unknown strings falls back to .pending
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self)) ?? ""
        self = ConnectionStatus(rawValue: raw) ?? .pending
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

struct Connection: Identifiable {
    let id: String
    let uids: [String]
    let initiator: String
    let status: ConnectionStatus
    let createdAt: Timestamp?
    let updatedAt: Timestamp?
    let lastActionBy: String?
}
