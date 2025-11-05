//
//  PartnerSurpriseHomeCard.swift
//  sevgilim
//
//  Created by refactoring HomeView
//  Displays partner's surprise with countdown

import SwiftUI

struct PartnerSurpriseHomeCard: View {
    let surprise: Surprise
    let onTap: () -> Void
    let onOpen: () -> Void
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showConfetti = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "gift.fill")
                            .font(.body)
                            .foregroundColor(.pink)
                        Text(surprise.isLocked ? "Gizli Sürpriz" : (surprise.shouldReveal ? "Sürpriz Hazır!" : surprise.title))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // Content
                if surprise.isLocked {
                    lockedContent
                } else if surprise.shouldReveal && !surprise.isOpened {
                    readyToOpenContent
                } else {
                    openedContent
                }
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .confetti(isActive: showConfetti)
        .onAppear {
            setupTimer()
            startPulseAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Content Views
    
    private var lockedContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text(surprise.isManuallyHidden ? "Sürprizi hazırlayan henüz paylaşmak istemiyor." : "İçeriği görmek için zamanı bekle!")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 12)
            
            if !surprise.isManuallyHidden {
                Text("Açılışa Kalan Süre")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)
                
                // Kompakt geri sayım
                HStack(spacing: 12) {
                    TimeUnitCompactSmall(value: days, unit: "Gün")
                    Text(":")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title3)
                    TimeUnitCompactSmall(value: hours, unit: "Saat")
                    Text(":")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title3)
                    TimeUnitCompactSmall(value: minutes, unit: "Dk")
                    Text(":")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.title3)
                    TimeUnitCompactSmall(value: seconds, unit: "Sn")
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var readyToOpenContent: some View {
        VStack(spacing: 8) {
            Text("🎉 Sürprizi açmak için dokun!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 12)
        }
        .padding(.bottom, 16)
    }
    
    private var openedContent: some View {
        VStack(spacing: 6) {
            Text("Açılmış Sürpriz")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 12)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Computed Properties
    
    private var days: Int {
        return Int(timeRemaining) / 86400
    }
    
    private var hours: Int {
        return (Int(timeRemaining) % 86400) / 3600
    }
    
    private var minutes: Int {
        return (Int(timeRemaining) % 3600) / 60
    }
    
    private var seconds: Int {
        return Int(timeRemaining) % 60
    }
    
    // MARK: - Functions
    
    private func setupTimer() {
        timeRemaining = max(0, surprise.timeRemaining)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseAnimation = true
        }
    }
}

// MARK: - Time Unit Component

private struct TimeUnitCompactSmall: View {
    let value: Int
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 40)
    }
}
