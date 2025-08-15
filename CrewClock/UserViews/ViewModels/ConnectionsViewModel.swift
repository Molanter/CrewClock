//
//  ConnectionsViewModel.swift
//  CrewClock
//
//  Created by Edgars Yarmolatiy on 8/14/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ConnectionsViewModel: ObservableObject {
    @Published var user: UserFB?
    @Published var sentInvites: Set<String> = []
    @Published var notificationUID: String? = nil
    @Published var connections: [Connection] = []
    
    private var db = Firestore.firestore()
    private var auth = Auth.auth()
    private let notificationsVM = NotificationsViewModel()
    
    private func connectionId(_ a: String, _ b: String) -> String {
        let pair = [a, b].sorted()
        return "\(pair[0])_\(pair[1])"
    }

    private func connectionRef(_ a: String, _ b: String) -> DocumentReference {
        db.collection("connections").document(connectionId(a, b))
    }
    
    
    // MARK: One-time fetch of ALL relationships for current user
    func fetchAllConnections() {
        guard let me = Auth.auth().currentUser?.uid else {
            self.connections = []
            return
        }
        
        let baseQuery = db.collection("connections")
            .whereField("uids", arrayContains: me)
        
        let orderedQuery = baseQuery.order(by: "updatedAt", descending: true)
        
        // Helper to map a snapshot → [Connection]
        func mapConnections(_ snap: QuerySnapshot?) -> [Connection] {
            return (snap?.documents ?? []).map { doc in
                let d = doc.data()
                return Connection(
                    id: doc.documentID,
                    uids: d["uids"] as? [String] ?? [],
                    initiator: d["initiator"] as? String ?? "",
                    status: d["status"] as? String ?? "",
                    createdAt: d["createdAt"] as? Timestamp,
                    updatedAt: d["updatedAt"] as? Timestamp,
                    lastActionBy: d["lastActionBy"] as? String
                )
            }
        }
        
        // Try the indexed query first
        orderedQuery.getDocuments { [weak self] snap, err in
            guard let self = self else { return }
            
            if let err = err as NSError? {
                // Missing index = failedPrecondition; fall back to un-ordered + in-memory sort
                let isMissingIndex =
                err.domain == "FIRFirestoreErrorDomain" &&
                err.code == FirestoreErrorCode.failedPrecondition.rawValue
                
                if isMissingIndex {
                    print("ℹ️ fetchAllConnections: missing index; falling back to client-side sort. Create the composite index for (uids ARRAY_CONTAINS, updatedAt DESC) to enable server-side ordering.")
                    baseQuery.getDocuments { [weak self] snap2, err2 in
                        guard let self = self else { return }
                        if let err2 = err2 {
                            print("❌ fetchAllConnections fallback error: \(err2.localizedDescription)")
                            self.connections = []
                            return
                        }
                        var conns = mapConnections(snap2)
                        conns.sort {
                            ($0.updatedAt?.dateValue() ?? .distantPast) >
                            ($1.updatedAt?.dateValue() ?? .distantPast)
                        }
                        DispatchQueue.main.async { self.connections = conns }
                    }
                    return
                } else {
                    print("❌ fetchAllConnections error: \(err.localizedDescription)")
                    self.connections = []
                    return
                }
            }
            
            // Success (indexed path)
            let conns = mapConnections(snap)
            DispatchQueue.main.async { self.connections = conns }
        }
    }
    
    // MARK: Realtime listener for ALL connections for current user
    // Returns a ListenerRegistration so you can stop listening when needed.
    @discardableResult
    func listenAllConnections(onChange: @escaping ([Connection]) -> Void) -> ListenerRegistration? {
        guard let me = Auth.auth().currentUser?.uid else {
            onChange([])
            return nil
        }
        let query = db.collection("connections")
            .whereField("uids", arrayContains: me)
            .order(by: "updatedAt", descending: true)

        let listener = query.addSnapshotListener { snap, err in
            if let err = err {
                print("❌ listenAllConnections error: \(err.localizedDescription)")
                onChange([])
                return
            }
            let rels: [Connection] = (snap?.documents ?? []).map { doc in
                let d = doc.data()
                return Connection(
                    id: doc.documentID,
                    uids: d["uids"] as? [String] ?? [],
                    initiator: d["initiator"] as? String ?? "",
                    status: d["status"] as? String ?? "",
                    createdAt: d["createdAt"] as? Timestamp,
                    updatedAt: d["updatedAt"] as? Timestamp,
                    lastActionBy: d["lastActionBy"] as? String
                )
            }
            onChange(rels)
        }
        return listener
    }
    
    //MARK: Connect with person
    func connectWithPerson(_ otherUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        sentInvites.insert(otherUid)
        self.notificationUID = otherUid

        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        // Idempotent upsert: create if missing, or refresh a declined/removed back to pending
        db.runTransaction({ txn, errorPointer in
            do {
                let snap = try txn.getDocument(ref)
                if snap.exists, let data = snap.data(), let cur = data["status"] as? String {
                    // If already accepted or blocked, do nothing (or handle re-request policy)
                    if cur == "accepted" || cur == "blocked" {
                        return nil
                    }
                    // Move to pending again if declined/removed, or keep pending
                    txn.updateData([
                        "status": "pending",
                        "initiator": me,
                        "lastActionBy": me,
                        "updatedAt": now
                    ], forDocument: ref)
                } else {
                    txn.setData([
                        "uids": [me, otherUid],
                        "initiator": me,
                        "status": "pending",
                        "roles": [:],                 // optional
                        "createdAt": now,
                        "updatedAt": now,
                        "lastActionBy": me
                    ], forDocument: ref)
                }
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("❌ Send request failed: \(error.localizedDescription)")
                return
            }
            print("Looks like everything is good ✅")
            // Notify the other user
            let newNotification = NotificationModel(
                title: "Do you want to connect?",
                message: "\(self.user?.name ?? self.auth.currentUser?.displayName ?? "Someone") sent a connection invite. Respond to it in the app.",
                timestamp: Date(),
                recipientUID: [otherUid],
                fromUID: self.user?.uid ?? self.auth.currentUser?.uid ?? "",
                isRead: false,
                type: .connectInvite,
                relatedId: self.connectionId(me, otherUid) // 👈 point to the connection
            )
            self.notificationsVM.getFcmByUid(uid: otherUid, notification: newNotification)
        }
    }
    
    func debugConnection(with otherUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let ref = connectionRef(me, otherUid)
        ref.getDocument { snap, err in
            let data = snap?.data() ?? [:]
            let status = data["status"] as? String ?? "nil"
            let initiator = data["initiator"] as? String ?? "nil"
            let uids = data["uids"] as? [String] ?? []
            print("🔎 rel(uids=\(uids)) status=\(status) initiator=\(initiator) me=\(me) other=\(otherUid)")
        }
    }
        
    // MARK: Accept connection (non-initiator accepts pending)
    func acceptConnection(from otherUid: String, notificationId: String? = nil) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, ep in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists, let data = snap.data() else {
                    ep?.pointee = NSError(domain: "Connection", code: 404,
                                          userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
                    return nil
                }

                let status    = data["status"] as? String ?? ""
                let initiator = data["initiator"] as? String ?? ""

                // If it's already accepted → idempotent success (no error)
                if status == "accepted" {
                    return ["initiator": initiator] as NSDictionary
                }

                // Only the non-initiator can accept, and only when pending
                guard status == "pending" else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Not pending"])
                    return nil
                }
                guard initiator != me else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "You created this invite—only the other user can accept"])
                    return nil
                }

                txn.updateData([
                    "status": "accepted",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)

                return ["initiator": initiator] as NSDictionary
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
        }) { result, error in
            if let error = error {
                print("❌ Accept failed: \(error.localizedDescription)")
                return
            }else {
                print("✅ No error here")
            }

            if let notificationId {
                self.notificationsVM.updateNotificationStatus(
                    notificationId: notificationId, newStatus: .accepted
                ) { _ in }
            }

            let initiator = (result as? [String: Any])?["initiator"] as? String
            let notifyUid = initiator ?? otherUid
            let connection = self.connectionId(me, otherUid)

            let n = NotificationModel(
                title: "You’re connected",
                message: "\(self.user?.name ?? self.auth.currentUser?.displayName ?? "Someone") accepted your connection request.",
                timestamp: Date(),
                recipientUID: [notifyUid],
                fromUID: self.user?.uid ?? self.auth.currentUser?.uid ?? "",
                isRead: false,
                type: .connectInvite,
                relatedId: connection
            )
            self.notificationsVM.getFcmByUid(uid: notifyUid, notification: n)
        }
    }

    // MARK: Cancel a pending invite (initiator only)
    func cancelInvite(to otherUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, ep in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists, let data = snap.data() else {
                    ep?.pointee = NSError(domain: "Connection", code: 404,
                                          userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
                    return nil
                }
                let status    = data["status"] as? String ?? ""
                let initiator = data["initiator"] as? String ?? ""

                guard status == "pending", initiator == me else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Only the initiator can cancel a pending invite"])
                    return nil
                }

                txn.updateData([
                    "status": "removed",           // or "cancelled" if you prefer a distinct state
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("❌ Cancel failed: \(error.localizedDescription)")
            } else {
                print("✅ Invite cancelled")
            }
        }
    }

    //MARK: Decline connection
    func declineConnection(from requesterUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let ref = connectionRef(me, requesterUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, errorPointer in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists,
                      let data = snap.data(),
                      let status = data["status"] as? String,
                      let initiator = data["initiator"] as? String
                else {
                    errorPointer?.pointee = NSError(domain: "Connection", code: 404)
                    return nil
                }

                guard status == "pending", initiator == requesterUid else {
                    errorPointer?.pointee = NSError(domain: "Connection", code: 409)
                    return nil
                }

                txn.updateData([
                    "status": "declined",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("❌ Decline failed: \(error.localizedDescription)")
                return
            }
            // (Optional) notify/requester, or stay silent
        }
    }
    
    //MARK: Remove connection
    func removeConnection(_ otherUid: String) {
        guard let me = Auth.auth().currentUser?.uid else { return }
        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, errorPointer in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists else {
                    errorPointer?.pointee = NSError(domain: "Connection", code: 404, userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
                    return nil
                }
                let currentStatus = snap.data()?["status"] as? String ?? ""
                guard currentStatus == "accepted" else {
                    errorPointer?.pointee = NSError(domain: "Connection", code: 409, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
                    return nil
                }
                txn.updateData([
                    "status": "removed",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("❌ Remove connection failed: \(error.localizedDescription)")
            } else {
                print("✅ Connection marked as removed")
            }
        }
    }
}
