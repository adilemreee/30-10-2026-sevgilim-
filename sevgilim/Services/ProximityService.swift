//
//  ProximityService.swift
//  sevgilim
//
//  Proximity notification service - notifies when partners are nearby
//

import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import UserNotifications

@MainActor
class ProximityService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Published Properties
    @Published var partnerLocation: CLLocation?
    @Published var userLocation: CLLocation?
    @Published var distanceToPartner: Double?
    @Published var isNearby: Bool = false
    @Published var isTrackingEnabled: Bool = false
    @Published var lastNotificationTime: Date?
    
    // MARK: - Settings (UserDefaults backed)
    @Published var proximityThreshold: Double {
        didSet {
            UserDefaults.standard.set(proximityThreshold, forKey: "proximityThreshold")
            checkProximity() // Threshold değişince yeniden hesapla
            updateGeofenceRegion() // Threshold değişince çitin boyutunu güncelle
        }
    }
    
    @Published var proximityNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(proximityNotificationsEnabled, forKey: "proximityNotificationsEnabled")
        }
    }
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var locationListener: ListenerRegistration?
    private var locationManager: CLLocationManager?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    // Cooldown: 10 dakika
    private let notificationCooldown: TimeInterval = 10 * 60
    
    // MARK: - Threshold Options
    static let thresholdOptions: [(label: String, value: Double)] = [
        ("100 metre", 100),
        ("250 metre", 250),
        ("500 metre", 500),
        ("1 kilometre", 1000)
    ]
    
    // MARK: - Init
    override init() {
        let savedThreshold = UserDefaults.standard.double(forKey: "proximityThreshold")
        self.proximityThreshold = savedThreshold == 0 ? 500 : savedThreshold
        
        self.proximityNotificationsEnabled = UserDefaults.standard.bool(forKey: "proximityNotificationsEnabled")
        
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Manager Setup
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.distanceFilter = 50 // 50 metre değişince güncelle
    }
    
    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.userLocation = location
            self.checkProximity()
            
            // Firebase'e konum güncelle
            if let userId = self.currentUserId {
                self.updateUserLocationToFirebase(userId: userId, location: location)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.permissionStatus = status
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.locationManager?.startUpdatingLocation()
            }
        }
    }
    
    // MARK: - Start/Stop Tracking
    func startTracking(userId: String, partnerId: String, relationshipId: String) {
        // User ID'yi güncelle
        self.currentUserId = userId
        
        if isTrackingEnabled {
            // Zaten tracking açıksa, sadece konumları yeniden al ve hesapla
            forceRefresh()
            print("🔄 Proximity tracking refreshed")
            return
        }
        
        isTrackingEnabled = true
        
        // Partner konumunu dinle
        startListeningToPartnerLocation(partnerId: partnerId)
        
        // Konum güncellemelerini başlat
        startLocationUpdates()
        
        print("✅ Proximity tracking started for user: \(userId), partner: \(partnerId)")
    }
    
    func stopTracking() {
        isTrackingEnabled = false
        locationListener?.remove()
        locationListener = nil
        locationManager?.stopUpdatingLocation()
        currentUserId = nil
        distanceToPartner = nil
        partnerLocation = nil
        userLocation = nil
        
        print("🔴 Proximity tracking stopped")
    }
    
    // MARK: - Start Location Updates
    private func startLocationUpdates() {
        guard let locationManager = locationManager else { return }
        
        // Always authorization iste
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
        
        // Konum güncellemelerini başlat
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            
            // İlk konum varsa hemen kullan
            if let location = locationManager.location {
                self.userLocation = location
                checkProximity()
                
                // Firebase'e ilk konumu da gönder
                if let userId = currentUserId {
                    updateUserLocationToFirebase(userId: userId, location: location)
                }
            }
        }
    }
    
    // MARK: - Partner Location Listener
    private func startListeningToPartnerLocation(partnerId: String) {
        locationListener?.remove()
        
        locationListener = db.collection("userLocations")
            .document(partnerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Partner location error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double else {
                    return
                }
                
                Task { @MainActor in
                    self.partnerLocation = CLLocation(latitude: latitude, longitude: longitude)
                    self.checkProximity()
                    self.updateGeofenceRegion() // Partner konumu değişince çiti güncelle
                }
            }
    }
    
    // MARK: - Update User Location to Firebase
    private func updateUserLocationToFirebase(userId: String, location: CLLocation) {
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: Date()),
            "accuracy": location.horizontalAccuracy
        ]
        
        db.collection("userLocations")
            .document(userId)
            .setData(locationData, merge: true) { error in
                if let error = error {
                    print("❌ Location update error: \(error.localizedDescription)")
                } else {
                    print("📍 Location updated")
                }
            }
    }
    
    // MARK: - Force Refresh (can be called from outside)
    func forceRefresh() {
        // Mevcut konumu al ve hesapla
        if let location = locationManager?.location {
            self.userLocation = location
        }
        checkProximity()
        
        // Firebase'e konumu güncelle
        if let userId = currentUserId, let location = userLocation {
            updateUserLocationToFirebase(userId: userId, location: location)
        }
    }
    
    // MARK: - Check Proximity
    private func checkProximity() {
        // userLocation property'sini veya locationManager'ın konumunu kullan
        let currentUserLocation = userLocation ?? locationManager?.location
        
        guard let userLoc = currentUserLocation,
              let partnerLoc = partnerLocation else {
            distanceToPartner = nil
            isNearby = false
            return
        }
        
        let distance = userLoc.distance(from: partnerLoc)
        distanceToPartner = distance
        
        let wasNearby = isNearby
        isNearby = distance <= proximityThreshold
        
        print("📍 Distance calculated: \(Int(distance))m (threshold: \(Int(proximityThreshold))m)")
        
        // Yeni yakınlaşma olduysa bildirim gönder
        if isNearby && !wasNearby && proximityNotificationsEnabled {
            sendProximityNotification(distance: distance)
        }
        
        // Hibrit Pil Modu Yönetimi
        checkDistanceAndToggleMode(distance: distance)
    }
    
    // MARK: - Hybrid Battery Mode
    private func checkDistanceAndToggleMode(distance: Double) {
        guard let locationManager = locationManager else { return }
        
        // Eğer mesafe > 2km ise GPS'i kapat, sadece Geofence dinle
        if distance > 2000 {
            if isTrackingEnabled && locationManager.desiredAccuracy != kCLLocationAccuracyThreeKilometers {
                locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                locationManager.distanceFilter = 500 // 500m
                print("🔋 Hybrid Mode: Switching to Low Power (Far away)")
            }
        } else {
            // Yakındaysa yüksek hassasiyet
            if isTrackingEnabled && locationManager.desiredAccuracy != kCLLocationAccuracyHundredMeters {
                locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager.distanceFilter = 50 // 50m
                print("⚡️ Hybrid Mode: Switching to High Accuracy (Nearby)")
            }
        }
    }
    
    // MARK: - Permission Status
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    private func updatePermissionStatus(_ status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.permissionStatus = status
        }
    }
    
    // MARK: - Send Notification
    private func sendProximityNotification(distance: Double) {
        // Cooldown kontrolü
        if let lastTime = lastNotificationTime,
           Date().timeIntervalSince(lastTime) < notificationCooldown {
            print("⏳ Notification cooldown active")
            return
        }
        
        lastNotificationTime = Date()
        
        let content = UNMutableNotificationContent()
        content.title = "💕 Yakınındasınız!"
        content.body = formatDistanceMessage(distance)
        content.sound = .default
        content.categoryIdentifier = "PROXIMITY"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Hemen gönder
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            } else {
                print("💕 Proximity notification sent!")
            }
        }
    }
    
    private func formatDistanceMessage(_ distance: Double) -> String {
        if distance < 100 {
            return "Aşkınızzz çok yakınında! 💑"
        } else if distance < 500 {
            return "Aşkınızzz yaklaşık \(Int(distance)) metre uzaklıkta"
        } else {
            let km = distance / 1000
            return String(format: "Aşkınızzz yaklaşık %.1f km uzaklıkta", km)
        }
    }
    
    // MARK: - Distance Formatted
    var distanceFormatted: String? {
        guard let distance = distanceToPartner else { return nil }
        
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            let km = distance / 1000
            return String(format: "%.1f km", km)
        }
    }
    
    // MARK: - Geofencing Logic
    private func updateGeofenceRegion() {
        guard let partnerLoc = partnerLocation else { return }
        
        // Önceki regionları temizle
        stopMonitoringRegions()
        
        // Yeni region oluştur
        let region = CLCircularRegion(
            center: partnerLoc.coordinate,
            radius: proximityThreshold,
            identifier: "PartnerProximityRegion"
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager?.startMonitoring(for: region)
        print("🌐 Geofence updated: Center \(partnerLoc.coordinate), Radius: \(proximityThreshold)m")
    }
    
    private func stopMonitoringRegions() {
        guard let locationManager = locationManager else { return }
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate Region Methods
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("📍 Did enter region: \(region.identifier)")
        
        Task { @MainActor in
            // Uygulama uyandı, hemen konum güncellemesi yap
            self.forceRefresh()
            
            // Eğer bildirim gönderilmediyse tetikle
            if let partnerLoc = self.partnerLocation,
               let userLoc = self.userLocation {
                let distance = userLoc.distance(from: partnerLoc)
                if distance <= self.proximityThreshold {
                    self.sendProximityNotification(distance: distance)
                }
            } else {
                 // Konumlar o an hazır değilse bile generic bildirim gönder
                 self.sendProximityNotification(distance: 0) // 0 implies unknown but close
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("📍 Did exit region: \(region.identifier)")
        // Çıkışta özel bir işlem gerekirse buraya eklenebilir
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopTracking()
        cancellables.removeAll()
    }
    
    deinit {
        locationListener?.remove()
    }
}
