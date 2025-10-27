//
//  AddStoryView.swift
//  sevgilim
//

import SwiftUI
import PhotosUI

struct AddStoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storyService: StoryService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceOptions = false
    @State private var showingEditor = false
    @StateObject private var uploadState = UploadState(message: "Story yükleniyor...")
    
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
                
                VStack(spacing: 20) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Story Ekle")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("24 saat görünür olacak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Image Preview or Picker Button
                    if let image = selectedImage {
                        // Image Preview with overlay buttons
                        VStack(spacing: 16) {
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 500)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                // Overlay: change photo & edit buttons side by side
                                VStack {
                                    HStack(spacing: 12) {
                                        Spacer()
                                        
                                        // Change Photo Button
                                        Button(action: { showingSourceOptions = true }) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                        .disabled(uploadState.isUploading)
                                        
                                        // Edit Button
                                        Button(action: { showingEditor = true }) {
                                            Image(systemName: "pencil.and.outline")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                        .disabled(uploadState.isUploading)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        // Upload Button
                        Button(action: uploadStory) {
                            HStack {
                                if uploadState.isUploading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Story'yi Paylaş")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .background(themeManager.currentTheme.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(uploadState.isUploading)
                        .opacity(uploadState.isUploading ? 0.6 : 1.0)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                    } else {
                        // Image Picker Button
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            themeManager.currentTheme.primaryColor,
                                            themeManager.currentTheme.secondaryColor
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(0.6)
                            
                            Text("Fotoğraf Seç")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Story olarak paylaşmak için\nbir fotoğraf seçin")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 12) {
                                // Kamera butonu
                                Button(action: { showingCamera = true }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                        Text("Kamera")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(themeManager.currentTheme.primaryColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                // Galeri butonu
                                Button(action: { showingImagePicker = true }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 24))
                                        Text("Galeri")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(themeManager.currentTheme.secondaryColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("İptal")
                        }
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    CameraPicker(image: $selectedImage)
                        .ignoresSafeArea()
                }
            }
            .confirmationDialog("Fotoğraf Seç", isPresented: $showingSourceOptions) {
                Button("Kamera") {
                    showingCamera = true
                }
                Button("Galeri") {
                    showingImagePicker = true
                }
                Button("İptal", role: .cancel) { }
            }
            .overlay(UploadStatusOverlay(state: uploadState))
            .alert(
                "Hata",
                isPresented: Binding(
                    get: { uploadState.errorMessage != nil },
                    set: { if !$0 { uploadState.errorMessage = nil } }
                )
            ) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(uploadState.errorMessage ?? "")
            }
            // Editör sayfasını buradan açıyoruz
            .sheet(isPresented: $showingEditor) {
                if selectedImage != nil {
                    StoryEditorView(image: $selectedImage)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
        
    // MARK: - Upload Story
    private func uploadStory() {
        guard let image = selectedImage,
              let userId = authService.currentUser?.id,
              let relationshipId = authService.currentUser?.relationshipId,
              let userName = authService.currentUser?.name else {
            uploadState.fail(with: "Kullanıcı bilgileri alınamadı")
            return
        }
        
        uploadState.start(message: "Story yükleniyor...")
        
        Task {
            do {
                _ = try await storyService.uploadStory(
                    relationshipId: relationshipId,
                    userId: userId,
                    userName: userName,
                    userPhotoURL: authService.currentUser?.profileImageURL,
                    image: image
                )
                
                await MainActor.run {
                    uploadState.finish()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    uploadState.fail(with: "Story yüklenirken hata oluştu: \\(error.localizedDescription)")
                }
            }
        }
    }
}
