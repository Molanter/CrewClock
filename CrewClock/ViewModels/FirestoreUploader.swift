//
//  FirestoreManager.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/9/25.
//

import SwiftUI
import FirebaseFirestore

enum FirestoreManagerError: Error {
    case encodingNotSupported
}

final class FirestoreManager {
    private let db: Firestore

    init(db: Firestore = .firestore()) { self.db = db }

    /// Create with optional document ID in a collection path, returns new docID.
    /// Pass raw Firestore data. Models do NOT need to conform to Encodable.
    func add(
        _ data: [String: Any],
        to collection: FirestoreCollectionPath,
        docID: String? = nil
    ) async throws -> String {
        var payload = data
        payload["createdAt"] = FieldValue.serverTimestamp()
        payload["updatedAt"] = FieldValue.serverTimestamp()
        let ref = docID != nil ? collection.col(in: db).document(docID!) : collection.col(in: db).document()
        try await ref.setData(payload)
        return ref.documentID
    }

    /// Upsert to a specific document path, returns document ID.
    /// Pass raw Firestore data. Models do NOT need to conform to Encodable.
    func upsert(
        _ data: [String: Any],
        at path: FirestorePath,
        merge: Bool = true
    ) async throws -> String {
        var payload = data
        if merge {
            payload["updatedAt"] = FieldValue.serverTimestamp()
        } else {
            payload["createdAt"] = FieldValue.serverTimestamp()
            payload["updatedAt"] = FieldValue.serverTimestamp()
        }
        try await path.doc(in: db).setData(payload, merge: merge)
        return path.doc(in: db).documentID
    }
    
    @available(*, deprecated, message: "Use the dictionary-based add(_:to:docID:) instead.")
    func add<T: Encodable>(_ value: T, to collection: FirestoreCollectionPath, docID: String? = nil, extra: [String: Any] = [:]) async throws -> String {
        throw FirestoreManagerError.encodingNotSupported
    }
    
    @available(*, deprecated, message: "Use the dictionary-based upsert(_:at:merge:) instead.")
    func upsert<T: Encodable>(_ value: T, at path: FirestorePath, merge: Bool = true, extra: [String: Any] = [:]) async throws -> String {
        throw FirestoreManagerError.encodingNotSupported
    }
    
    /// Delete a document at the given path.
    func delete(at path: FirestorePath) async throws {
        try await path.doc(in: db).delete()
    }
    
    
}
