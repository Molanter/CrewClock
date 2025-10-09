//
//  ProjectViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 6/3/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProjectViewModel: ObservableObject {
    @Published var projects: [ProjectFB] = []
    private let manager = FirestoreManager()
    private let db = Firestore.firestore()

    func fetchProjects() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let projectsRef = db.collection("projects")
        let ownerQuery = projectsRef.whereField("owner", isEqualTo: userId)
        let crewQuery = projectsRef.whereField("crew", arrayContains: userId)

        let group = DispatchGroup()
        var fetchedDocuments: [QueryDocumentSnapshot] = []
        var documentIds: Set<String> = []

        // Fetch projects where user is owner
        group.enter()
        ownerQuery.getDocuments { (querySnapshot, error) in
            if let docs = querySnapshot?.documents {
                fetchedDocuments.append(contentsOf: docs)
                for doc in docs { documentIds.insert(doc.documentID) }
            }
            group.leave()
        }

        // Fetch projects where user is in crew
        group.enter()
        crewQuery.getDocuments { (querySnapshot, error) in
            if let docs = querySnapshot?.documents {
                // Only add if not already in set (to dedupe)
                for doc in docs where !documentIds.contains(doc.documentID) {
                    fetchedDocuments.append(doc)
                }
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            var processedProjects: [ProjectFB] = []
            for document in fetchedDocuments {
                var data = document.data()
                let docId = document.documentID
                data["documentID"] = docId
                let projectModel = ProjectFB(data: data, documentId: docId)
                processedProjects.append(projectModel)
            }
            self?.projects = processedProjects
        }
    }

    func addProject(_ project: Project) async {
        let checklistDicts = project.checklist.map { ["text": $0.text, "isChecked": $0.isChecked] }
        let data: [String: Any] = [
            "projectName": project.projectName,
            "owner": project.owner,
            "crew": project.crew,
            "checklist": checklistDicts,
            "comments": project.comments,
            "color": project.color,
            "startDate": Timestamp(date: project.startDate),
            "finishDate": Timestamp(date: project.finishDate),
            "active": project.active
        ]
        do {
            let projectId = try await manager.add(data, to: FSPath.Projects())
            print("✅ Project added successfully with id: \(projectId)")
            await MainActor.run { self.fetchProjects() }
        } catch {
            print("❌ Error adding project: \(error.localizedDescription)")
        }
    }

    func updateProject(documentId: String, with project: Project) async {
        let checklistDicts = project.checklist.map { ["text": $0.text, "isChecked": $0.isChecked] }
        let data: [String: Any] = [
            "projectName": project.projectName,
            "owner": project.owner,
            "crew": project.crew,
            "checklist": checklistDicts,
            "comments": project.comments,
            "color": project.color,
            "startDate": Timestamp(date: project.startDate),
            "finishDate": Timestamp(date: project.finishDate),
            "active": project.active
        ]
        do {
            _ = try await manager.upsert(data, at: FSPath.Project(id: documentId), merge: true)
            print("✅ Project updated successfully")
            await MainActor.run { self.fetchProjects() }
        } catch {
            print("❌ Error updating project: \(error.localizedDescription)")
        }
    }
    
    func updateChecklist(documentId: String, checklist: [ChecklistItem]) async {
        let checklistDicts = checklist.map { ["text": $0.text, "isChecked": $0.isChecked] }
        let data: [String: Any] = [
            "checklist": checklistDicts
        ]
        do {
            _ = try await manager.upsert(data, at: FSPath.Project(id: documentId), merge: true)
            print("✅ Checklist updated successfully")
            await MainActor.run { self.fetchProjects() }
        } catch {
            print("❌ Error updating checklist: \(error.localizedDescription)")
        }
    }

    func deleteProject(_ project: ProjectFB) async {
        do {
            try await manager.delete(at: FSPath.Project(id: project.id))
            print("✅ Project deleted successfully")
            await MainActor.run { self.fetchProjects() }
        } catch {
            print("❌ Error deleting project: \(error.localizedDescription)")
        }
    }
    
    func fetchProject(by id: String, completion: @escaping (ProjectFB?) -> Void) {
        db.collection("projects").document(id).getDocument { document, error in
            if let document = document, document.exists {
                var data = document.data() ?? [:]
                data["documentID"] = document.documentID
                let project = ProjectFB(data: data, documentId: document.documentID)
                completion(project)
            } else {
                print("❌ Project not found or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    func addCrewMember(documentId: String, crewMember: String) {
        let ref = db.collection("projects").document(documentId)
        ref.updateData([
            "crew": FieldValue.arrayUnion([crewMember])
        ]) { error in
            if let error = error {
                print("❌ Error adding crew member: \(error.localizedDescription)")
            } else {
                print("✅ Crew member added successfully")
                self.fetchProjects()
            }
        }
    }

    func removeCrewMember(documentId: String, crewMember: String) {
        let ref = db.collection("projects").document(documentId)
        ref.updateData([
            "crew": FieldValue.arrayRemove([crewMember])
        ]) { error in
            if let error = error {
                print("❌ Error removing crew member: \(error.localizedDescription)")
            } else {
                print("✅ Crew member removed successfully")
                self.fetchProjects()
            }
        }
    }
    
}
