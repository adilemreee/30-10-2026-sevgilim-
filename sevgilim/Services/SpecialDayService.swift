//
//  SpecialDayService.swift
//  sevgilim
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class SpecialDayService: ObservableObject {
    @Published var specialDays: [SpecialDay] = []
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let offlineCache = OfflineDataManager.shared
    
    func listenToSpecialDays(relationshipId: String) {
        print("🔵 Starting listener for relationshipId: \(relationshipId)")
        listener?.remove()
        
        // 🔥 Offline-first: Önce önbellekten yükle
        if let cachedDays = offlineCache.loadSpecialDays(), !cachedDays.isEmpty {
            self.specialDays = cachedDays
            print("⚡ SpecialDayService: \(cachedDays.count) özel gün önbellekten yüklendi")
        }
        
        listener = db.collection("specialDays")
            .whereField("relationshipId", isEqualTo: relationshipId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { 
                    print("❌ Self is nil in listener")
                    return 
                }
                
                if let error = error {
                    print("❌ Error listening to special days: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents in snapshot")
                    DispatchQueue.main.async {
                        self.specialDays = []
                    }
                    return
                }
                
                print("📦 Received \(documents.count) documents from Firestore")
                
                let days = documents.compactMap { doc -> SpecialDay? in
                    do {
                        let day = try doc.data(as: SpecialDay.self)
                        print("✅ Decoded: \(day.title)")
                        return day
                    } catch {
                        print("❌ Error decoding special day: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    // Sort by date on client side
                    self.specialDays = days.sorted { $0.date < $1.date }
                    print("✅ Updated specialDays array with \(self.specialDays.count) items")
                    
                    // 💾 Önbelleğe kaydet
                    self.offlineCache.saveSpecialDays(days.sorted { $0.date < $1.date })
                }
            }
    }
    
    func addSpecialDay(
        relationshipId: String,
        userId: String,
        title: String,
        date: Date,
        category: SpecialDayCategory,
        notes: String?,
        isRecurring: Bool
    ) async throws {
        let specialDay = SpecialDay(
            relationshipId: relationshipId,
            title: title,
            date: date,
            category: category,
            icon: category.icon,
            color: category.defaultColor,
            notes: notes,
            isRecurring: isRecurring,
            createdAt: Date(),
            createdBy: userId
        )
        
        do {
            let _ = try await db.collection("specialDays").addDocument(from: specialDay)
            print("✅ Special day added successfully")
        } catch {
            print("❌ Error adding special day: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateSpecialDay(_ specialDay: SpecialDay) async throws {
        guard let id = specialDay.id else {
            throw NSError(domain: "SpecialDayService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Special day ID is missing"])
        }
        
        try db.collection("specialDays").document(id).setData(from: specialDay)
        print("✅ Special day updated successfully")
    }
    
    func deleteSpecialDay(_ specialDay: SpecialDay) async throws {
        guard let id = specialDay.id else {
            throw NSError(domain: "SpecialDayService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Special day ID is missing"])
        }
        
        try await db.collection("specialDays").document(id).delete()
        print("✅ Special day deleted successfully")
    }
    
    // Yaklaşan özel günleri getir (30 gün içinde)
    func upcomingSpecialDays(within days: Int = 30) -> [SpecialDay] {
        return specialDays
            .filter { !$0.isPast && $0.daysUntil <= days }
            .sorted { $0.daysUntil < $1.daysUntil }
    }
    
    // Bugünkü özel günler
    func todaySpecialDays() -> [SpecialDay] {
        return specialDays.filter { $0.isToday }
    }
    
    // En yakın özel gün
    func nextSpecialDay() -> SpecialDay? {
        return specialDays
            .filter { !$0.isPast }
            .sorted { $0.daysUntil < $1.daysUntil }
            .first
    }
    
    deinit {
        listener?.remove()
    }
}
