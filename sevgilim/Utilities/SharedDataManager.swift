//
//  SharedDataManager.swift
//  sevgilim
//
//  Manages shared data between main app and widget via App Groups
//

import Foundation

/// Keys for shared UserDefaults
enum SharedDataKey: String {
    case partnerName = "partner_name"
    case user1Name = "user1_name"
    case user2Name = "user2_name"
    case startDate = "relationship_start_date"
    case lastUpdated = "last_updated"
}

/// Manages data sharing between main app and widget extension
final class SharedDataManager {
    
    static let shared = SharedDataManager()
    
    /// App Group identifier - must match what's configured in Xcode
    private let appGroupId = "group.com.sevgilim.shared"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }
    
    private init() {}
    
    // MARK: - Save Data
    
    /// Saves relationship data to shared storage for widget access
    func saveRelationshipData(
        user1Name: String,
        user2Name: String,
        startDate: Date
    ) {
        guard let defaults = sharedDefaults else {
            print("❌ SharedDataManager: Could not access App Group")
            return
        }
        
        defaults.set(user1Name, forKey: SharedDataKey.user1Name.rawValue)
        defaults.set(user2Name, forKey: SharedDataKey.user2Name.rawValue)
        defaults.set(startDate, forKey: SharedDataKey.startDate.rawValue)
        defaults.set(Date(), forKey: SharedDataKey.lastUpdated.rawValue)
        
        print("✅ SharedDataManager: Saved relationship data for widget")
    }
    
    // MARK: - Read Data
    
    /// Gets the relationship start date
    var startDate: Date? {
        sharedDefaults?.object(forKey: SharedDataKey.startDate.rawValue) as? Date
    }
    
    /// Gets user 1 name
    var user1Name: String {
        sharedDefaults?.string(forKey: SharedDataKey.user1Name.rawValue) ?? "Sen"
    }
    
    /// Gets user 2 name
    var user2Name: String {
        sharedDefaults?.string(forKey: SharedDataKey.user2Name.rawValue) ?? "Sevgilin"
    }
    
    /// Calculates days since relationship started
    var daysTogether: Int {
        guard let startDate = startDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    /// Last update time
    var lastUpdated: Date? {
        sharedDefaults?.object(forKey: SharedDataKey.lastUpdated.rawValue) as? Date
    }
}
