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
    @Published var notificationUID: String?
    @Published var connections: [Connection] = []

    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let notificationsVM = NotificationsViewModel()

    // MARK: Helpers
    private func connectionId(_ a: String, _ b: String) -> String {
        let pair = [a, b].sorted()
        return "\(pair[0])_\(pair[1])"
    }

    private func connectionRef(_ a: String, _ b: String) -> DocumentReference {
        db.collection("connections").document(connectionId(a, b))
    }

    private func mapConnections(_ snap: QuerySnapshot?) -> [Connection] {
        (snap?.documents ?? []).map { doc in
            let d = doc.data()
            return Connection(
                id: doc.documentID,
                uids: d["uids"] as? [String] ?? [],
                initiator: d["initiator"] as? String ?? "",
                status: ConnectionStatus(rawValue: d["status"] as? String ?? "") ?? .pending,
                createdAt: d["createdAt"] as? Timestamp,
                updatedAt: d["updatedAt"] as? Timestamp,
                lastActionBy: d["lastActionBy"] as? String
            )
        }
    }

    // MARK: One-time fetch of ALL relationships for arbitrary user
    func fetchAllConnections(for uid: String) {
        let baseQuery = db.collection("connections").whereField("uids", arrayContains: uid)
        let orderedQuery = baseQuery.order(by: "updatedAt", descending: true)

        orderedQuery.getDocuments { [weak self] snap, err in
            guard let self else { return }

            if let err = err as NSError? {
                let missingIndex =
                    err.domain == "FIRFirestoreErrorDomain" &&
                    err.code == FirestoreErrorCode.failedPrecondition.rawValue
                if missingIndex {
                    // Fallback without order. Sort on client.
                    baseQuery.getDocuments { [weak self] snap2, err2 in
                        guard let self else { return }
                        if let err2 { print("❌ fetchAllConnections fallback: \(err2.localizedDescription)"); self.connections = []; return }
                        var conns = self.mapConnections(snap2)
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

            let conns = self.mapConnections(snap)
            DispatchQueue.main.async { self.connections = conns }
        }
    }

    /// Convenience: current signed-in user
    func fetchAllConnections() {
        guard let me = auth.currentUser?.uid else { self.connections = []; return }
        fetchAllConnections(for: me)
    }

    // MARK: Realtime listener for arbitrary user
    @discardableResult
    func listenAllConnections(for uid: String, onChange: @escaping ([Connection]) -> Void) -> ListenerRegistration {
        let query = db.collection("connections")
            .whereField("uids", arrayContains: uid)
            .order(by: "updatedAt", descending: true)

        let listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            if let err { print("❌ listenAllConnections error: \(err.localizedDescription)"); onChange([]); return }
            onChange(self.mapConnections(snap))
        }
        return listener
    }

    /// Convenience: realtime for current user
    @discardableResult
    func listenAllConnections(onChange: @escaping ([Connection]) -> Void) -> ListenerRegistration? {
        guard let me = auth.currentUser?.uid else { onChange([]); return nil }
        return listenAllConnections(for: me, onChange: onChange)
    }

    // MARK: Connect with person (current user context)
    func connectWithPerson(_ otherUid: String) {
        guard let me = auth.currentUser?.uid else { return }
        sentInvites.insert(otherUid)
        notificationUID = otherUid

        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, ep in
            do {
                let snap = try txn.getDocument(ref)
                if snap.exists, let data = snap.data(), let cur = data["status"] as? String {
                    if cur == "accepted" || cur == "blocked" { return nil }
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
                        "roles": [:],
                        "createdAt": now,
                        "updatedAt": now,
                        "lastActionBy": me
                    ], forDocument: ref)
                }
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
            return nil
        }) { [weak self] _, error in
            guard let self else { return }
            if let error { print("❌ Send request failed: \(error.localizedDescription)"); return }
            let n = NotificationModel(
                title: "Do you want to connect?",
                message: "\(self.user?.name ?? self.auth.currentUser?.displayName ?? "Someone") sent a connection invite. Respond in the app.",
                timestamp: Date(),
                recipientUID: [otherUid],
                fromUID: self.user?.uid ?? self.auth.currentUser?.uid ?? "",
                isRead: false,
                type: .connectInvite,
                relatedId: self.connectionId(me, otherUid)
            )
            self.notificationsVM.getFcmByUid(uid: otherUid, notification: n)
        }
    }

    // MARK: Accept (current user must be the non-initiator)
    func acceptConnection(from otherUid: String, notificationId: String? = nil) {
        guard let me = auth.currentUser?.uid else { return }
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
                let status = data["status"] as? String ?? ""
                let initiator = data["initiator"] as? String ?? ""

                if status == "accepted" { return ["initiator": initiator] as NSDictionary }
                guard status == "pending" else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Not pending"])
                    return nil
                }
                guard initiator != me else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Initiator cannot accept"])
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
        }) { [weak self] result, error in
            guard let self else { return }
            if let error { print("❌ Accept failed: \(error.localizedDescription)"); return }

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
                message: "\(self.user?.name ?? self.auth.currentUser?.displayName ?? "Someone") \(NotificationType.connectionAccepted.message)",
                timestamp: Date(),
                recipientUID: [notifyUid],
                fromUID: self.user?.uid ?? self.auth.currentUser?.uid ?? "",
                isRead: false,
                type: .connectionAccepted,
                relatedId: connection
            )
            self.notificationsVM.getFcmByUid(uid: notifyUid, notification: n)
        }
    }

    // MARK: Cancel pending (initiator only)
    func cancelInvite(to otherUid: String) {
        guard let me = auth.currentUser?.uid else { return }
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
                let status = data["status"] as? String ?? ""
                let initiator = data["initiator"] as? String ?? ""

                guard status == "pending", initiator == me else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Only initiator can cancel pending"])
                    return nil
                }

                txn.updateData([
                    "status": "removed",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
            return nil
        }) { _, error in
            if let error { print("❌ Cancel failed: \(error.localizedDescription)") }
        }
    }

    // MARK: Decline pending (non-initiator)
    func declineConnection(from requesterUid: String) {
        guard let me = auth.currentUser?.uid else { return }
        let ref = connectionRef(me, requesterUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, ep in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists,
                      let data = snap.data(),
                      let status = data["status"] as? String,
                      let initiator = data["initiator"] as? String
                else {
                    ep?.pointee = NSError(domain: "Connection", code: 404); return nil
                }
                guard status == "pending", initiator == requesterUid else {
                    ep?.pointee = NSError(domain: "Connection", code: 409); return nil
                }
                txn.updateData([
                    "status": "declined",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
            return nil
        }) { _, error in
            if let error { print("❌ Decline failed: \(error.localizedDescription)") }
        }
    }

    // MARK: Remove existing connection
    func removeConnection(_ otherUid: String) {
        guard let me = auth.currentUser?.uid else { return }
        let ref = connectionRef(me, otherUid)
        let now = Timestamp(date: Date())

        db.runTransaction({ txn, ep in
            do {
                let snap = try txn.getDocument(ref)
                guard snap.exists else {
                    ep?.pointee = NSError(domain: "Connection", code: 404,
                                          userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
                    return nil
                }
                let cur = snap.data()?["status"] as? String ?? ""
                guard cur == "accepted" else {
                    ep?.pointee = NSError(domain: "Connection", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Not connected"])
                    return nil
                }
                txn.updateData([
                    "status": "removed",
                    "updatedAt": now,
                    "lastActionBy": me
                ], forDocument: ref)
            } catch let e as NSError {
                ep?.pointee = e
                return nil
            }
            return nil
        }) { _, error in
            if let error { print("❌ Remove connection failed: \(error.localizedDescription)") }
        }
    }
}
