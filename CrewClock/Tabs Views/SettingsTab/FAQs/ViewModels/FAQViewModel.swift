//
//  FAQViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/23/25.
//


import Foundation
import FirebaseFirestore

@MainActor
final class FAQViewModel: ObservableObject {
    @Published var faqs: [FAQ] = []
    @Published var filtered: [FAQ] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filters
    @Published var searchText: String = "" { didSet { applyFilters() } }
    @Published var selectedTag: String? = nil { didSet { applyFilters() } }

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let collectionPath = "faqs"

    deinit { listener?.remove() }

    func startListening() {
        guard listener == nil else { return }
        isLoading = true
        errorMessage = nil

        listener = db.collection(collectionPath)
            .order(by: "order", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let docs = snapshot?.documents else {
                    self.faqs = []; self.filtered = []
                    return
                }
                do {
                    self.faqs = try docs.compactMap { try $0.data(as: FAQ.self) }
                    self.applyFilters()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // One-shot fetch; keeps all FAQs in memory and filters locally
    func loadOnce() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let snapshot = try await db.collection(collectionPath)
                .order(by: "order", descending: false)
                .getDocuments()
            let items: [FAQ] = try snapshot.documents.compactMap { doc in
                try doc.data(as: FAQ.self)
            }
            await MainActor.run {
                self.faqs = items
                self.applyFilters()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func applyFilters() {
        var list = faqs
        if let tag = selectedTag, !tag.isEmpty {
            list = list.filter { $0.tags.map { $0.lowercased() }.contains(tag.lowercased()) }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.question.lowercased().contains(q) || $0.answer.lowercased().contains(q) }
        }
        filtered = list
    }

    var allTags: [String] {
        let set = Set(faqs.flatMap { $0.tags })
        return Array(set).sorted()
    }
}
