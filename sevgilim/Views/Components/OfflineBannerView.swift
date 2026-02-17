//
//  OfflineBannerView.swift
//  sevgilim
//
//  Shows a banner when the user is offline
//  Also shows sync status when coming back online
//

import SwiftUI

struct OfflineBannerView: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @ObservedObject private var syncManager = OfflineSyncManager.shared
    
    @State private var showBanner = false
    @State private var bannerOffset: CGFloat = -60
    
    var body: some View {
        VStack(spacing: 0) {
            if showBanner {
                HStack(spacing: 10) {
                    if syncManager.isSyncing {
                        // Senkronizasyon yapılıyor
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Senkronize ediliyor...")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    } else if !networkMonitor.isConnected {
                        // Çevrimdışı
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Çevrimdışı  •  Önbellekten gösteriliyor")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    } else if syncManager.pendingOperations > 0 {
                        // Bekleyen işlemler var
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("\(syncManager.pendingOperations) bekleyen işlem")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if syncManager.pendingOperations > 0 && networkMonitor.isConnected && !syncManager.isSyncing {
                        Button {
                            Task {
                                await syncManager.syncNow()
                            }
                        } label: {
                            Text("Senkronize Et")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(bannerColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(bannerColor)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBanner)
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            updateBannerVisibility()
            
            // Bağlantı geri gelince banner'ı 3 saniye sonra gizle
            if isConnected && syncManager.pendingOperations == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        if networkMonitor.isConnected && syncManager.pendingOperations == 0 {
                            showBanner = false
                        }
                    }
                }
            }
        }
        .onChange(of: syncManager.pendingOperations) { _, _ in
            updateBannerVisibility()
        }
        .onChange(of: syncManager.isSyncing) { _, isSyncing in
            if !isSyncing && syncManager.pendingOperations == 0 {
                // Senkronizasyon tamamlandı
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        if syncManager.pendingOperations == 0 {
                            showBanner = false
                        }
                    }
                }
            }
        }
    }
    
    private var bannerColor: Color {
        if syncManager.isSyncing {
            return .blue
        } else if !networkMonitor.isConnected {
            return .orange
        } else if syncManager.pendingOperations > 0 {
            return .yellow.opacity(0.8)
        }
        return .orange
    }
    
    private func updateBannerVisibility() {
        withAnimation {
            showBanner = !networkMonitor.isConnected || syncManager.pendingOperations > 0 || syncManager.isSyncing
        }
    }
}

#Preview {
    VStack {
        OfflineBannerView()
        Spacer()
    }
}
