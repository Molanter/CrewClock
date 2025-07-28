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
    private var db = Firestore.firestore()

    func fetchProjects() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let projectsRef = db.collection("projects")
        projectsRef
            .whereField("owner", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching projects: \(error.localizedDescription)")
                } else if let documents = querySnapshot?.documents {
                    var processedProjects: [ProjectFB] = []

                    for document in documents {
                        var data = document.data()
                        let docId = document.documentID
                        data["documentID"] = docId
                        let projectModel = ProjectFB(data: data, documentId: docId)
                        processedProjects.append(projectModel)
                    }

                    self?.projects = processedProjects
                } else {
                    print("No documents found")
                    self?.projects = []
                }
            }
    }

    func addProject(_ project: ProjectModel) {
        let projectData: [String: Any] = [
            "projectName": project.projectName,
            "owner": project.owner,
            "crew": project.crew,
            "checklist": project.checklist.map { ["text": $0.text, "isChecked": $0.isChecked] },
            "comments": project.comments,
            "color": project.color,
            "startDate": Timestamp(date: project.startDate),
            "finishDate": Timestamp(date: project.finishDate),
            "active": project.active,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("projects").addDocument(data: projectData) { error in
            if let error = error {
                print("Error adding project: \(error.localizedDescription)")
            }else {
                print("✅ Project added successfully")
                self.fetchProjects()
            }
        }
    }

    func updateProject(documentId: String, with project: ProjectModel) {
        let ref = db.collection("projects").document(documentId)

        let updateData: [String: Any] = [
            "projectName": project.projectName,
            "owner": project.owner,
            "crew": project.crew,
            "checklist": project.checklist.map { ["text": $0.text, "isChecked": $0.isChecked] },
            "comments": project.comments,
            "color": project.color,
            "startDate": Timestamp(date: project.startDate),
            "finishDate": Timestamp(date: project.finishDate),
            "active": project.active
        ]

        ref.updateData(updateData) { error in
            if let error = error {
                print("❌ Error updating project: \(error.localizedDescription)")
            } else {
                print("✅ Project updated successfully")
                self.fetchProjects()
            }
        }
    }
    
    func updateChecklist(documentId: String, checklist: [ChecklistItem]) {
        let ref = db.collection("projects").document(documentId)
        let checklistData = checklist.map { ["text": $0.text, "isChecked": $0.isChecked] }
        
        ref.updateData(["checklist": checklistData]) { error in
            if let error = error {
                print("❌ Error updating checklist: \(error.localizedDescription)")
            } else {
                print("✅ Checklist updated successfully")
                self.fetchProjects()
            }
        }
    }

    func deleteProject(_ project: ProjectFB) {
        let id = project.id
        db.collection("projects").document(id).delete { error in
            if let error = error {
                print("Error deleting project: \(error.localizedDescription)")
            }else {
                print("✅ Project deleted successfully")
                self.fetchProjects()
            }
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
