//
//  SharedUserDefaults.swift
//  sevgilim
//
//  App Group shared UserDefaults for iPhone ↔ Watch data sharing
//

import Foundation

/// Shared UserDefaults manager using App Groups
/// Allows data sharing between iPhone app and Watch app
final class SharedUserDefaults {
    
    // MARK: - Singleton
    static let shared = SharedUserDefaults()
    
    // MARK: - Constants
    private let suiteName = "group.com.sevgilim.shared"
    
    // MARK: - Keys
    enum Keys: String {
        // User Data
        case userId = "shared_userId"
        case userName = "shared_userName"
        case userEmail = "shared_userEmail"
        
        // Partner Data
        case partnerId = "shared_partnerId"
        case partnerName = "shared_partnerName"
        
        // Relationship Data
        case relationshipId = "shared_relationshipId"
        case relationshipStartDate = "shared_relationshipStartDate"
        case isPaired = "shared_isPaired"
        case themeColor = "shared_themeColor"
        
        // Sync Data
        case lastSyncTime = "shared_lastSyncTime"
        case lastHeartbeatSentAt = "shared_lastHeartbeatSentAt"
        case lastHeartbeatReceivedAt = "shared_lastHeartbeatReceivedAt"
        
        // Watch Specific
        case watchConnected = "shared_watchConnected"
        case watchLastActiveAt = "shared_watchLastActiveAt"
        
        // Mood
        case currentMood = "shared_currentMood"
        case currentMoodEmoji = "shared_currentMoodEmoji"
        case partnerMood = "shared_partnerMood"
        case partnerMoodEmoji = "shared_partnerMoodEmoji"
    }
    
    // MARK: - Properties
    private let defaults: UserDefaults?
    
    // MARK: - Init
    private init() {
        self.defaults = UserDefaults(suiteName: suiteName)
        
        if defaults == nil {
            print("⚠️ SharedUserDefaults: Failed to initialize with suite name: \(suiteName)")
        }
    }
    
    // MARK: - Generic Accessors
    
    func set(_ value: Any?, forKey key: Keys) {
        defaults?.set(value, forKey: key.rawValue)
        defaults?.synchronize()
    }
    
    func string(forKey key: Keys) -> String? {
        return defaults?.string(forKey: key.rawValue)
    }
    
    func bool(forKey key: Keys) -> Bool {
        return defaults?.bool(forKey: key.rawValue) ?? false
    }
    
    func date(forKey key: Keys) -> Date? {
        return defaults?.object(forKey: key.rawValue) as? Date
    }
    
    func remove(forKey key: Keys) {
        defaults?.removeObject(forKey: key.rawValue)
        defaults?.synchronize()
    }
    
    // MARK: - User Data
    
    var userId: String? {
        get { string(forKey: .userId) }
        set { set(newValue, forKey: .userId) }
    }
    
    var userName: String? {
        get { string(forKey: .userName) }
        set { set(newValue, forKey: .userName) }
    }
    
    var userEmail: String? {
        get { string(forKey: .userEmail) }
        set { set(newValue, forKey: .userEmail) }
    }
    
    // MARK: - Partner Data
    
    var partnerId: String? {
        get { string(forKey: .partnerId) }
        set { set(newValue, forKey: .partnerId) }
    }
    
    var partnerName: String? {
        get { string(forKey: .partnerName) }
        set { set(newValue, forKey: .partnerName) }
    }
    
    // MARK: - Relationship Data
    
    var relationshipId: String? {
        get { string(forKey: .relationshipId) }
        set { set(newValue, forKey: .relationshipId) }
    }
    
    var relationshipStartDate: Date? {
        get { date(forKey: .relationshipStartDate) }
        set { set(newValue, forKey: .relationshipStartDate) }
    }
    
    var isPaired: Bool {
        get { bool(forKey: .isPaired) }
        set { set(newValue, forKey: .isPaired) }
    }
    
    var themeColor: String? {
        get { string(forKey: .themeColor) }
        set { set(newValue, forKey: .themeColor) }
    }
    
    // MARK: - Sync Data
    
    var lastSyncTime: Date? {
        get { date(forKey: .lastSyncTime) }
        set { set(newValue, forKey: .lastSyncTime) }
    }
    
    var lastHeartbeatSentAt: Date? {
        get { date(forKey: .lastHeartbeatSentAt) }
        set { set(newValue, forKey: .lastHeartbeatSentAt) }
    }
    
    var lastHeartbeatReceivedAt: Date? {
        get { date(forKey: .lastHeartbeatReceivedAt) }
        set { set(newValue, forKey: .lastHeartbeatReceivedAt) }
    }
    
    // MARK: - Watch Data
    
    var watchConnected: Bool {
        get { bool(forKey: .watchConnected) }
        set { set(newValue, forKey: .watchConnected) }
    }
    
    var watchLastActiveAt: Date? {
        get { date(forKey: .watchLastActiveAt) }
        set { set(newValue, forKey: .watchLastActiveAt) }
    }
    
    // MARK: - Mood Data
    
    var currentMood: String? {
        get { string(forKey: .currentMood) }
        set { set(newValue, forKey: .currentMood) }
    }
    
    var currentMoodEmoji: String? {
        get { string(forKey: .currentMoodEmoji) }
        set { set(newValue, forKey: .currentMoodEmoji) }
    }
    
    var partnerMood: String? {
        get { string(forKey: .partnerMood) }
        set { set(newValue, forKey: .partnerMood) }
    }
    
    var partnerMoodEmoji: String? {
        get { string(forKey: .partnerMoodEmoji) }
        set { set(newValue, forKey: .partnerMoodEmoji) }
    }
    
    // MARK: - Helper Methods
    
    /// Check if we have valid sync data
    var hasSyncData: Bool {
        userId != nil && userName != nil
    }
    
    /// Check if paired with partner
    var hasPartner: Bool {
        partnerId != nil && partnerName != nil
    }
    
    /// Clear all shared data (on logout)
    func clearAll() {
        Keys.allCases.forEach { key in
            remove(forKey: key)
        }
    }
}

// MARK: - CaseIterable for Keys
extension SharedUserDefaults.Keys: CaseIterable {}
