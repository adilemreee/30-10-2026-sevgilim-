//
//  Surprise.swift
//  sevgilim
//

import Foundation
import FirebaseFirestore

struct Surprise: Identifiable, Codable {
    @DocumentID var id: String?
    var relationshipId: String
    var title: String
    var message: String
    var photoURL: String?
    var revealDate: Date // Açılış tarihi
    var createdBy: String // userId (kimin hazırladığı)
    var createdFor: String // userId (kimin için hazırlandığı)
    var createdAt: Date
    var isOpened: Bool // Açıldı mı?
    var openedAt: Date? // Açıldığı an
    var isManuallyHidden: Bool = false // Oluşturan tarafından elle gizlendi mi?
    
    enum CodingKeys: String, CodingKey {
        case id
        case relationshipId
        case title
        case message
        case photoURL
        case revealDate
        case createdBy
        case createdFor
        case createdAt
        case isOpened
        case openedAt
        case isManuallyHidden
    }
    
    // Sürprizin kilitli olup olmadığını kontrol et
    var isLocked: Bool {
        if isManuallyHidden {
            return true
        }
        guard !isOpened else { return false }
        return Date() < revealDate
    }
    
    // Geri sayım için kalan süreyi hesapla
    var timeRemaining: TimeInterval {
        return max(0, revealDate.timeIntervalSince(Date()))
    }
    
    // Süre doldu mu?
    var shouldReveal: Bool {
        guard !isOpened else { return false }
        if isManuallyHidden {
            return false
        }
        return Date() >= revealDate
    }
}
