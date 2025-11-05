//
//  SurpriseDetailView.swift
//  sevgilim
//

import SwiftUI
import Combine

struct SurpriseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var surpriseService: SurpriseService
    
    let surprise: Surprise
    let partnerName: String
    let isCreatedByCurrentUser: Bool
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: AnyCancellable?
    @State private var showDeleteAlert = false
    @State private var cachedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var showFullScreenPhoto = false
    @State private var isUpdatingVisibility = false
    
    private var currentSurprise: Surprise {
        surpriseService.surprises.first(where: { $0.id == surprise.id }) ?? surprise
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.primaryColor.opacity(0.3),
                        themeManager.currentTheme.secondaryColor.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Durum Göstergesi
                        if currentSurprise.isLocked && !isCreatedByCurrentUser {
                            // Kilitli Sürpriz
                            lockedContentView
                        } else if currentSurprise.shouldReveal && !currentSurprise.isOpened && !isCreatedByCurrentUser {
                            // Açılmaya Hazır ama henüz açılmamış
                            readyButNotOpenedView
                        } else {
                            // Açık İçerik veya Kendi Oluşturduğu
                            openContentView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                }
            }
            .navigationTitle("Sürpriz Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                if isCreatedByCurrentUser {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Sürprizi Sil", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    Task {
                        await deleteSurprise()
                    }
                }
            } message: {
                Text("Bu sürprizi silmek istediğinizden emin misiniz?")
            }
            .fullScreenCover(isPresented: $showFullScreenPhoto) {
                if let cachedImage = cachedImage {
                    SimpleSurprisePhotoViewer(image: cachedImage, dismiss: {
                        showFullScreenPhoto = false
                    })
                }
            }
            .onAppear {
                setupTimer()
                loadCachedImage()
            }
            .onDisappear {
                timer?.cancel()
            }
        }
    }
    
    // MARK: - Kilitli İçerik
    
    private var lockedContentView: some View {
        let surprise = currentSurprise
        return VStack(spacing: 25) {
            // İkon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
            
            // Başlık
            Text("Gizli Sürpriz")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Mesaj
            Text(surprise.isManuallyHidden ?
                 "Bu sürpriz şu an için gizlendi. İçeriğini görmek için biraz daha sabretmelisin." :
                    "Bu sürpriz henüz kilitli. İçeriği görmek için belirlenen tarihi beklemen gerekiyor.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Kimden
            VStack(spacing: 8) {
                Text("Kimden")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(partnerName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Geri Sayım
            if !surprise.isManuallyHidden {
                VStack(spacing: 15) {
                    Text("Açılışa Kalan Süre")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        TimeUnitLarge(value: days, unit: "Gün")
                        TimeUnitLarge(value: hours, unit: "Saat")
                        TimeUnitLarge(value: minutes, unit: "Dakika")
                        TimeUnitLarge(value: seconds, unit: "Saniye")
                    }
                    
                    Text(surprise.revealDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(surprise.revealDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Açılmaya Hazır ama Açılmamış
    
    private var readyButNotOpenedView: some View {
        let surprise = currentSurprise
        return VStack(spacing: 25) {
            // İkon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            .padding(.top, 20)
            
            // Başlık
            Text("Sürpriz Hazır!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Mesaj
            Text("Bu sürpriz açılmaya hazır! Sürpriz listesinden açabilirsin.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Kimden
            VStack(spacing: 8) {
                Text("Kimden")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(partnerName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Tarih Bilgisi
            VStack(spacing: 10) {
                Text("Açılış Tarihi")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    Label(surprise.revealDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                    Label(surprise.revealDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Açık İçerik
    
    private var openContentView: some View {
        let surprise = currentSurprise
        return VStack(spacing: 20) {
            // Durum İkonu
            if surprise.isOpened {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }
                .padding(.top, 10)
            }
            
            if isCreatedByCurrentUser {
                Button(action: { toggleManualHidden(for: surprise) }) {
                    HStack(spacing: 6) {
                        if isUpdatingVisibility {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: surprise.isManuallyHidden ? "eye.fill" : "eye.slash.fill")
                                .font(.caption)
                            Text(surprise.isManuallyHidden ? "Sürprizi Göster" : "Tekrar Gizle")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ).opacity(0.8)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingVisibility)
            }
            
            if isCreatedByCurrentUser && surprise.isManuallyHidden {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.yellow)
                    Text("Bu sürpriz şu an manuel olarak gizlendi. Tekrar paylaşmak için \"Sürprizi Göster\"e dokun.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            
            // Başlık
            Text(surprise.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Kimden/Kime Bilgisi
            if isCreatedByCurrentUser {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    Text("Kime: \(partnerName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    Text("Kimden: \(partnerName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Fotoğraf
            if let photoURL = surprise.photoURL {
                Button(action: { showFullScreenPhoto = true }) {
                    Group {
                        if let cachedImage = cachedImage {
                            Image(uiImage: cachedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 400)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 8)
                        } else if isLoadingImage {
                            ZStack {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                
                                ProgressView()
                            }
                            .cornerRadius(16)
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Mesaj
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    Text("Mesaj")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(surprise.message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.top, 10)
            
            // Tarih Bilgileri
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Oluşturulma")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(surprise.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Açılış Tarihi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(surprise.revealDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                if surprise.isOpened {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Açıldı")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Time Unit Large
    
    private struct TimeUnitLarge: View {
        let value: Int
        let unit: String
        
        var body: some View {
            VStack(spacing: 6) {
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Computed Properties
    
    private var days: Int {
        let remaining = max(0, timeRemaining)
        return Int(remaining) / 86400
    }
    
    private var hours: Int {
        let remaining = max(0, timeRemaining)
        return (Int(remaining) % 86400) / 3600
    }
    
    private var minutes: Int {
        let remaining = max(0, timeRemaining)
        return (Int(remaining) % 3600) / 60
    }
    
    private var seconds: Int {
        let remaining = max(0, timeRemaining)
        return Int(remaining) % 60
    }
    
    // MARK: - Timer Setup
    
    private func setupTimer() {
        // İlk değeri hesapla
        let surprise = currentSurprise
        timeRemaining = surprise.timeRemaining
        
        // Eğer süre dolmuş veya açılmışsa timer başlatma
        guard !surprise.isOpened && surprise.isLocked else { return }
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let updated = currentSurprise
                let remaining = updated.timeRemaining
                if remaining > 0 && !updated.isOpened {
                    timeRemaining = remaining
                } else {
                    timer?.cancel()
                }
            }
    }
    
    // MARK: - Load Cached Image
    
    private func loadCachedImage() {
        guard let photoURL = currentSurprise.photoURL else { return }
        
        isLoadingImage = true
        
        Task {
            do {
                let image = try await ImageCacheService.shared.loadImage(from: photoURL)
                await MainActor.run {
                    self.cachedImage = image
                    self.isLoadingImage = false
                }
            } catch {
                print("❌ Error loading cached image: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }
    
    private func toggleManualHidden(for surprise: Surprise) {
        guard !isUpdatingVisibility else { return }
        
        let newHidden = !surprise.isManuallyHidden
        isUpdatingVisibility = true
        
        Task {
            do {
                try await surpriseService.updateManualHiddenStatus(for: surprise, hidden: newHidden)
            } catch {
                print("❌ Error updating surprise visibility: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isUpdatingVisibility = false
            }
        }
    }
    
    // MARK: - Delete Surprise
    
    private func deleteSurprise() async {
        do {
            try await surpriseService.deleteSurprise(currentSurprise)
            dismiss()
        } catch {
            print("❌ Sürpriz silinirken hata: \(error.localizedDescription)")
        }
    }
}

// MARK: - Simple Photo Viewer
struct SimpleSurprisePhotoViewer: View {
    let image: UIImage
    let dismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = max(1.0, min(scale * delta, 4.0))
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    offset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                if scale > 1.0 {
                    scale = 1.0
                    offset = .zero
                    lastOffset = .zero
                } else {
                    scale = 2.0
                }
            }
        }
    }
}
