//
//  FirestorePath.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 10/9/25.
//


import FirebaseFirestore

protocol FirestorePath {
    func doc(in db: Firestore) -> DocumentReference
}
protocol FirestoreCollectionPath {
    func col(in db: Firestore) -> CollectionReference
}

enum FSPath {
    case teams
    case team(id: String)
    case tasks
    case task(id: String)
    case projects
    case project(id: String)
    case log(projectId: String, id: String)
    case notifications
    case notification(id: String)
    case users
    case user(id: String)
    case connections(userId: String)
    case connection(userId: String, id: String)

    // Collection shortcuts
    struct Teams: FirestoreCollectionPath {
        func col(in db: Firestore) -> CollectionReference { db.collection("teams") }
    }
    struct Team: FirestorePath {
        let id: String
        func doc(in db: Firestore) -> DocumentReference { db.collection("teams").document(id) }
    }

    // MARK: - Tasks
    struct Tasks: FirestoreCollectionPath {
        func col(in db: Firestore) -> CollectionReference {
            db.collection("tasks")
        }
    }
    struct Task: FirestorePath {
        let id: String
        func doc(in db: Firestore) -> DocumentReference {
            db.collection("tasks").document(id)
        }
    }

    // MARK: - Projects
    struct Projects: FirestoreCollectionPath {
        func col(in db: Firestore) -> CollectionReference {
            db.collection("projects")
        }
    }
    struct Project: FirestorePath {
        let id: String
        func doc(in db: Firestore) -> DocumentReference {
            db.collection("projects").document(id)
        }
    }

    // MARK: - Notifications
    struct Notifications: FirestoreCollectionPath {
        func col(in db: Firestore) -> CollectionReference {
            db.collection("notifications")
        }
    }
    struct Notification: FirestorePath {
        let id: String
        func doc(in db: Firestore) -> DocumentReference {
            db.collection("notifications").document(id)
        }
    }

    // MARK: - Users
    struct Users: FirestoreCollectionPath {
        func col(in db: Firestore) -> CollectionReference {
            db.collection("users")
        }
    }
    struct User: FirestorePath {
        let id: String
        func doc(in db: Firestore) -> DocumentReference {
            db.collection("users").document(id)
        }
    }

    // MARK: - Connections
    struct Connections: FirestoreCollectionPath {
        let userId: String
        func col(in db: Firestore) -> CollectionReference {
            db.collection("users").document(userId).collection("connections")
        }
    }
    struct Connection: FirestorePath {
        let userId: String
        let id: String
        func doc(in db: Firestore) -> DocumentReference {
            db.collection("users").document(userId).collection("connections").document(id)
        }
    }
}
