//
//  NetworkMonitor.swift
//  sevgilim
//
//  Real-time network connectivity monitor
//  Allows the app to detect offline/online state and react accordingly
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()
    
    // MARK: - Published State
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false // Cellular, hotspot etc.
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Hücresel"
        case wiredEthernet = "Kablolu"
        case unknown = "Bilinmiyor"
    }
    
    // MARK: - Private
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor.queue", qos: .utility)
    
    // Callbacks for offline/online transitions
    private var onConnectedCallbacks: [() -> Void] = []
    private var onDisconnectedCallbacks: [() -> Void] = []
    
    private init() {}
    
    // MARK: - Public API
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected
                let nowConnected = path.status == .satisfied
                
                self.isConnected = nowConnected
                self.isExpensive = path.isExpensive
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = .unknown
                }
                
                // Trigger transition callbacks
                if !wasConnected && nowConnected {
                    // Came back online
                    print("🌐 NetworkMonitor: Bağlantı geri geldi (\(self.connectionType.rawValue))")
                    self.onConnectedCallbacks.forEach { $0() }
                } else if wasConnected && !nowConnected {
                    // Went offline
                    print("📴 NetworkMonitor: Bağlantı kesildi")
                    self.onDisconnectedCallbacks.forEach { $0() }
                }
            }
        }
        
        monitor.start(queue: queue)
        print("📡 NetworkMonitor: İzleme başlatıldı")
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Callback Registration
    
    /// Register a callback for when the device comes back online
    func onConnected(_ callback: @escaping () -> Void) {
        onConnectedCallbacks.append(callback)
    }
    
    /// Register a callback for when the device goes offline
    func onDisconnected(_ callback: @escaping () -> Void) {
        onDisconnectedCallbacks.append(callback)
    }
    
    // MARK: - Convenience
    
    /// Whether we should download large media (not on expensive connection)
    var shouldDownloadLargeMedia: Bool {
        isConnected && !isExpensive
    }
    
    /// Whether any network operation is possible
    var canSync: Bool {
        isConnected
    }
}
