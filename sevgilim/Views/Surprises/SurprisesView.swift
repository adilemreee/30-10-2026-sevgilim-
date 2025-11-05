//
//  SurprisesView.swift
//  sevgilim
//

import SwiftUI

struct SurprisesView: View {
    @EnvironmentObject var surpriseService: SurpriseService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var relationshipService: RelationshipService
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showAddSurprise = false
    @State private var surpriseToDelete: Surprise?
    @State private var showDeleteConfirmation = false
    @State private var selectedSurprise: Surprise?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Temaya uyumlu
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.primaryColor.opacity(0.3),
                        themeManager.currentTheme.secondaryColor.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Compact Header (diğer sayfalar gibi)
                    HStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sürprizler")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("Aşkımaaa sürprizler")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Add Button
                        Button(action: { showAddSurprise = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            if surpriseService.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding(.top, 50)
                            } else if surpriseService.surprises.isEmpty {
                                emptyStateView
                            } else {
                                VStack(spacing: 30) {
                                    // Sana Gelen Sürprizler
                                    if !partnerSurprises.isEmpty {
                                        surpriseSection(
                                            title: "🎁 Sana Sürprizler",
                                            subtitle: "",
                                            surprises: partnerSurprises,
                                            showDeleteButton: false
                                        )
                                    }
                                    
                                    // Hazırladığın Sürprizler
                                    if !userSurprises.isEmpty {
                                        surpriseSection(
                                            title: "📦 Hazırladığın Sürprizler",
                                            subtitle: "",
                                            surprises: userSurprises,
                                            showDeleteButton: true
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddSurprise) {
                AddSurpriseView()
            }
            .sheet(item: $selectedSurprise) { surprise in
                SurpriseDetailView(
                    surprise: surprise,
                    partnerName: partnerName,
                    isCreatedByCurrentUser: surprise.createdBy == authService.currentUser?.id
                )
            }
            .alert("Sürprizi Sil", isPresented: $showDeleteConfirmation) {
                Button("İptal", role: .cancel) {
                    surpriseToDelete = nil
                }
                Button("Sil", role: .destructive) {
                    deleteSurprise()
                }
            } message: {
                Text("Bu sürprizi silmek istediğinizden emin misiniz?")
            }
            .onAppear {
                loadSurprises()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.primaryColor.opacity(0.5))
            
            Text("Henüz Sürpriz Yok")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("İlk sürprizi sen oluştur ve sevdiğin kişiyi mutlu et!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showAddSurprise = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("İlk Sürprizi Oluştur")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 10)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Surprise Section
    
    @ViewBuilder
    private func surpriseSection(
        title: String,
        subtitle: String,
        surprises: [Surprise],
        showDeleteButton: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section Header
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 5)
            
            // Sürpriz Kartları
            ForEach(surprises) { surprise in
                SurpriseCardView(
                    surprise: surprise,
                    isCreatedByCurrentUser: showDeleteButton,
                    partnerName: partnerName,
                    onOpen: {
                        markSurpriseAsOpened(surprise)
                    },
                    onToggleManualHidden: { hidden in
                        await toggleManualHidden(for: surprise, hidden: hidden)
                    }
                )
                .onTapGesture {
                    selectedSurprise = surprise
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var partnerSurprises: [Surprise] {
        guard let userId = authService.currentUser?.id else { return [] }
        return surpriseService.surprisesCreatedByPartner(userId: userId)
    }
    
    private var userSurprises: [Surprise] {
        guard let userId = authService.currentUser?.id else { return [] }
        return surpriseService.surprisesCreatedByUser(userId: userId)
    }
    
    private var partnerName: String {
        guard let relationship = relationshipService.currentRelationship,
              let currentUserId = authService.currentUser?.id else {
            return "Partner"
        }
        
        // Eğer user1 isen user2'nin adını, değilsen user1'in adını döndür
        if relationship.user1Id == currentUserId {
            return relationship.user2Name
        } else {
            return relationship.user1Name
        }
    }
    
    // MARK: - Functions
    
    private func loadSurprises() {
        guard let userId = authService.currentUser?.id,
              let relationshipId = relationshipService.currentRelationship?.id else {
            return
        }
        
        surpriseService.listenToSurprises(relationshipId: relationshipId, userId: userId)
    }
    
    private func markSurpriseAsOpened(_ surprise: Surprise) {
        Task {
            do {
                try await surpriseService.markAsOpened(surprise)
            } catch {
                print("❌ Error marking surprise as opened: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleManualHidden(for surprise: Surprise, hidden: Bool) async {
        guard surprise.createdBy == authService.currentUser?.id else { return }
        do {
            try await surpriseService.updateManualHiddenStatus(for: surprise, hidden: hidden)
        } catch {
            print("❌ Error updating surprise visibility: \(error.localizedDescription)")
        }
    }
    
    private func deleteSurprise() {
        guard let surprise = surpriseToDelete else { return }
        
        withAnimation {
            Task {
                do {
                    try await surpriseService.deleteSurprise(surprise)
                    surpriseToDelete = nil
                } catch {
                    print("❌ Error deleting surprise: \(error.localizedDescription)")
                }
            }
        }
    }
}
