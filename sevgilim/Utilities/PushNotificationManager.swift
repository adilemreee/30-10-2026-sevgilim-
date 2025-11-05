//
//  PushNotificationManager.swift
//  sevgilim
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class PushNotificationManager {
    static let shared = PushNotificationManager()

    private let db = Firestore.firestore()
    private let tokenDefaultsKey = "cachedFCMToken"
    private let notificationsEnabledKey = "pushNotificationsEnabled"
    private let queue = DispatchQueue(label: "PushNotificationManager.queue")

    private init() {}

    private var cachedToken: String? {
        get { UserDefaults.standard.string(forKey: tokenDefaultsKey) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: tokenDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenDefaultsKey)
            }
        }
    }
    
    var notificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }

    func updateFCMToken(_ token: String) {
        guard !token.isEmpty else { return }

        queue.async {
            let previousToken = self.cachedToken

            if previousToken == token {
                self.syncTokenWithCurrentUser()
                return
            }

            self.cachedToken = token

            if !self.notificationsEnabled {
                return
            }

            if let previousToken {
                self.removeTokenFromCurrentUser(previousToken)
            }

            self.syncTokenWithCurrentUser()
        }
    }

    func refreshIfNeeded() {
        guard notificationsEnabled else { return }

        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ FCM token alınamadı: \(error.localizedDescription)")
                return
            }

            guard let token = token else { return }
            self?.updateFCMToken(token)
        }
    }

    func syncTokenWithCurrentUser() {
        guard notificationsEnabled else { return }
        guard let token = cachedToken,
              let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await detachTokenFromOtherUsers(token: token, currentUserId: userId)
                try await db.collection("users").document(userId).setData([
                    "fcmTokens": FieldValue.arrayUnion([token]),
                    "fcmUpdatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            } catch {
                print("❌ FCM token Firestore'a yazılamadı: \(error.localizedDescription)")
            }
        }
    }

    func unregisterCurrentToken() {
        guard let token = cachedToken,
              let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "fcmTokens": FieldValue.arrayRemove([token])
                ])
                self.cachedToken = nil
            } catch {
                print("❌ FCM token silinemedi: \(error.localizedDescription)")
            }
        }
    }

    private func removeTokenFromCurrentUser(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "fcmTokens": FieldValue.arrayRemove([token])
                ])
            } catch {
                print("❌ Eski FCM token kaldırılamadı: \(error.localizedDescription)")
            }
        }
    }
    
    private func detachTokenFromOtherUsers(token: String, currentUserId: String) async throws {
        let snapshot = try await db.collection("users")
            .whereField("fcmTokens", arrayContains: token)
            .getDocuments()
        
        guard !snapshot.documents.isEmpty else { return }
        
        for document in snapshot.documents where document.documentID != currentUserId {
            do {
                try await document.reference.updateData([
                    "fcmTokens": FieldValue.arrayRemove([token])
                ])
            } catch {
                print("❌ Başka kullanıcıdan FCM token kaldırılamadı: \(error.localizedDescription)")
            }
        }
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
        
        queue.async {
            if enabled {
                self.refreshIfNeeded()
            } else {
                self.unregisterCurrentToken()
            }
        }
    }
}
