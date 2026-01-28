//
//  SharedModels.swift
//  sevgilim
//
//  Shared data models for iPhone ↔ Watch communication
//

import Foundation

// MARK: - Watch Sync Data
/// Primary data structure for syncing user/relationship info between iPhone and Watch
struct WatchSyncData: Codable {
    let userId: String
    let userName: String
    let userEmail: String
    let partnerId: String?
    let partnerName: String?
    let relationshipId: String?
    let relationshipStartDate: Date?
    let isPaired: Bool
    let themeColor: String?
    let lastSyncTime: Date
    
    init(
        userId: String,
        userName: String,
        userEmail: String,
        partnerId: String? = nil,
        partnerName: String? = nil,
        relationshipId: String? = nil,
        relationshipStartDate: Date? = nil,
        isPaired: Bool = false,
        themeColor: String? = nil
    ) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.partnerId = partnerId
        self.partnerName = partnerName
        self.relationshipId = relationshipId
        self.relationshipStartDate = relationshipStartDate
        self.isPaired = isPaired
        self.themeColor = themeColor
        self.lastSyncTime = Date()
    }
    
    /// Convert to dictionary for WatchConnectivity
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "userName": userName,
            "userEmail": userEmail,
            "isPaired": isPaired,
            "lastSyncTime": lastSyncTime.timeIntervalSince1970
        ]
        
        if let partnerId = partnerId { dict["partnerId"] = partnerId }
        if let partnerName = partnerName { dict["partnerName"] = partnerName }
        if let relationshipId = relationshipId { dict["relationshipId"] = relationshipId }
        if let relationshipStartDate = relationshipStartDate {
            dict["relationshipStartDate"] = relationshipStartDate.timeIntervalSince1970
        }
        if let themeColor = themeColor { dict["themeColor"] = themeColor }
        
        return dict
    }
    
    /// Initialize from dictionary received via WatchConnectivity
    init?(from dictionary: [String: Any]) {
        guard let userId = dictionary["userId"] as? String,
              let userName = dictionary["userName"] as? String,
              let userEmail = dictionary["userEmail"] as? String,
              let isPaired = dictionary["isPaired"] as? Bool,
              let lastSyncTimeInterval = dictionary["lastSyncTime"] as? TimeInterval else {
            return nil
        }
        
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.isPaired = isPaired
        self.lastSyncTime = Date(timeIntervalSince1970: lastSyncTimeInterval)
        
        self.partnerId = dictionary["partnerId"] as? String
        self.partnerName = dictionary["partnerName"] as? String
        self.relationshipId = dictionary["relationshipId"] as? String
        self.themeColor = dictionary["themeColor"] as? String
        
        if let startDateInterval = dictionary["relationshipStartDate"] as? TimeInterval {
            self.relationshipStartDate = Date(timeIntervalSince1970: startDateInterval)
        } else {
            self.relationshipStartDate = nil
        }
    }
}

// MARK: - Heartbeat Data
/// Data structure for heartbeat messages
struct HeartbeatData: Codable {
    let senderId: String
    let senderName: String
    let receiverId: String
    let timestamp: Date
    let message: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": "heartbeat",
            "senderId": senderId,
            "senderName": senderName,
            "receiverId": receiverId,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        if let message = message { dict["message"] = message }
        return dict
    }
    
    init(senderId: String, senderName: String, receiverId: String, message: String? = nil) {
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.timestamp = Date()
        self.message = message
    }
    
    init?(from dictionary: [String: Any]) {
        guard dictionary["type"] as? String == "heartbeat",
              let senderId = dictionary["senderId"] as? String,
              let senderName = dictionary["senderName"] as? String,
              let receiverId = dictionary["receiverId"] as? String,
              let timestampInterval = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.timestamp = Date(timeIntervalSince1970: timestampInterval)
        self.message = dictionary["message"] as? String
    }
}

// MARK: - Mood Data
/// Data structure for mood status sync
struct MoodData: Codable {
    let userId: String
    let mood: String
    let emoji: String
    let note: String?
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": "mood",
            "userId": userId,
            "mood": mood,
            "emoji": emoji,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        if let note = note { dict["note"] = note }
        return dict
    }
    
    init?(from dictionary: [String: Any]) {
        guard dictionary["type"] as? String == "mood",
              let userId = dictionary["userId"] as? String,
              let mood = dictionary["mood"] as? String,
              let emoji = dictionary["emoji"] as? String,
              let timestampInterval = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.userId = userId
        self.mood = mood
        self.emoji = emoji
        self.note = dictionary["note"] as? String
        self.timestamp = Date(timeIntervalSince1970: timestampInterval)
    }
}

// MARK: - Location Data
/// Data structure for location sync
struct LocationData: Codable {
    let userId: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: Double?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": "location",
            "userId": userId,
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        if let accuracy = accuracy { dict["accuracy"] = accuracy }
        return dict
    }
    
    init?(from dictionary: [String: Any]) {
        guard dictionary["type"] as? String == "location",
              let userId = dictionary["userId"] as? String,
              let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double,
              let timestampInterval = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.userId = userId
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date(timeIntervalSince1970: timestampInterval)
        self.accuracy = dictionary["accuracy"] as? Double
    }
}

// MARK: - Watch Message Types
enum WatchMessageType: String, Codable {
    case syncRequest = "sync_request"
    case syncResponse = "sync_response"
    case heartbeat = "heartbeat"
    case heartbeatReceived = "heartbeat_received"
    case mood = "mood"
    case location = "location"
    case voiceMessage = "voice_message"
    case connectionStatus = "connection_status"
    case error = "error"
}

// MARK: - Watch Message
/// Generic message wrapper for Watch ↔ iPhone communication
struct WatchMessage {
    let type: WatchMessageType
    let payload: [String: Any]
    let timestamp: Date
    
    init(type: WatchMessageType, payload: [String: Any] = [:]) {
        self.type = type
        self.payload = payload
        self.timestamp = Date()
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "messageType": type.rawValue,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        dict.merge(payload) { (_, new) in new }
        return dict
    }
    
    init?(from dictionary: [String: Any]) {
        guard let typeString = dictionary["messageType"] as? String,
              let type = WatchMessageType(rawValue: typeString),
              let timestampInterval = dictionary["timestamp"] as? TimeInterval else {
            return nil
        }
        
        self.type = type
        self.timestamp = Date(timeIntervalSince1970: timestampInterval)
        
        var payload = dictionary
        payload.removeValue(forKey: "messageType")
        payload.removeValue(forKey: "timestamp")
        self.payload = payload
    }
}
