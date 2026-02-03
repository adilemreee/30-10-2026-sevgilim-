//
//  PartnerLocationCard.swift
//  sevgilim
//
//  Displays real-time distance to partner using ProximityService
//

import SwiftUI
import CoreLocation

struct PartnerLocationCard: View {
    @ObservedObject var proximityService: ProximityService
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Aşkınızzzınn Konumu")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if proximityService.proximityNotificationsEnabled {
                // Tracking Active
                if let distance = proximityService.distanceFormatted {
                    Text(distance)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    if proximityService.isNearby {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Çok Yakınınızda!")
                                .font(.callout.bold())
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Uzaklık")
                            .font(.callout.bold())
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // Calculating or No Data
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Hesaplanıyor...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(height: 50)
                }
            } else {
                // Tracking Disabled
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Konum Takibi Kapalı")
                        .font(.callout.bold())
                        .foregroundColor(.white)
                    
                    Text("Ayarlardan etkinleştirebilirsiniz")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        .overlay(alignment: .bottom) {
            if proximityService.permissionStatus == .authorizedWhenInUse {
                Text("⚠️ Arka plan için 'Her Zaman' izni gerekli")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.red.opacity(0.8), in: Capsule())
                    .offset(y: 12)
            }
        }
        .onAppear {
            // Uygulama açıldığında veya view göründüğünde hesaplamayı tetikle
            if proximityService.proximityNotificationsEnabled {
                proximityService.forceRefresh()
            }
        }
    }
}
