//
//  NotificationsView.swift
//  sevgilim
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var relationshipService: RelationshipService
    @EnvironmentObject private var memoryService: MemoryService
    @EnvironmentObject private var photoService: PhotoService
    @EnvironmentObject private var noteService: NoteService
    @EnvironmentObject private var planService: PlanService
    @EnvironmentObject private var movieService: MovieService
    @EnvironmentObject private var placeService: PlaceService
    @EnvironmentObject private var songService: SongService
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var messageService: MessageService
    @EnvironmentObject private var surpriseService: SurpriseService
    @EnvironmentObject private var specialDayService: SpecialDayService
    @EnvironmentObject private var secretVaultService: SecretVaultService
    
    @State private var hasStartedMessageListener = false
    @AppStorage("notificationsClearedAt") private var notificationsClearedTimestamp: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 48, height: 5)
                .padding(.top, 8)
            
            HStack {
                Text("Bildirimler")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer()
                if hasAnyNotifications {
                    Button("Temizle") {
                        notificationsClearedTimestamp = Date().timeIntervalSince1970
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if notificationItems.isEmpty {
                        EmptyNotificationState(
                            systemImage: "bell.slash",
                            title: "Şimdilik Bildirim Yok",
                            message: "Mesajlar dışında yeni bir aktivite olursa burada göreceksin."
                        )
                    } else {
                        ForEach(notificationItems) { item in
                            NotificationRow(item: item)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .task {
            await startMessageListenerIfNeeded()
        }
    }
    
    private var hasAnyNotifications: Bool {
        !notificationItems.isEmpty
    }
    
    private var clearedDate: Date {
        Date(timeIntervalSince1970: notificationsClearedTimestamp)
    }
    
    private var notificationItems: [NotificationItem] {
        var items: [NotificationItem] = []
        items.append(contentsOf: partnerActivityItems)
        items.append(contentsOf: storyInteractionItems)
        items.append(contentsOf: surpriseItems)
        items.append(contentsOf: specialDayItems)
        items.append(contentsOf: secretVaultItems)
        
        return items
            .filter { $0.timestamp > clearedDate }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(50)
            .map { $0 }
    }
    
    private func startMessageListenerIfNeeded() async {
        guard !hasStartedMessageListener,
              let relationshipId = authService.currentUser?.relationshipId,
              let userId = authService.currentUser?.id else {
            return
        }
        
        hasStartedMessageListener = true
        messageService.listenToMessages(relationshipId: relationshipId, currentUserId: userId)
    }
    
    private var partnerActivityItems: [NotificationItem] {
        guard
            let currentUser = authService.currentUser,
            let relationship = relationshipService.currentRelationship,
            let currentUserId = currentUser.id else {
            return []
        }
        
        let partnerId = relationship.partnerId(for: currentUserId)
        let partnerName = relationship.partnerName(for: currentUserId)
        
        var items: [NotificationItem] = []
        
        let memories = memoryService.memories
            .filter { $0.createdBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) yeni bir anı ekledi",
                    message: "\"\($0.title)\"",
                    iconName: "sparkles.rectangle.stack",
                    timestamp: $0.createdAt
                )
            }
        
        let photos = photoService.photos
            .filter { $0.uploadedBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) galerimize fotoğraf ekledi",
                    message: $0.title ?? "Yeni bir fotoğraf paylaştı",
                    iconName: "photo.on.rectangle",
                    timestamp: $0.createdAt
                )
            }
        
        let notes = noteService.notes
            .filter { $0.createdBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) yeni bir not bıraktı",
                    message: "\"\($0.title)\"",
                    iconName: "note.text",
                    timestamp: $0.createdAt
                )
            }
        
        let plans = planService.plans
            .filter { $0.createdBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) planlarımıza ekleme yaptı",
                    message: "\"\($0.title)\" planı hazır",
                    iconName: "calendar.badge.plus",
                    timestamp: $0.createdAt
                )
            }
        
        let movies = movieService.movies
            .filter { $0.addedBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) film listesine ekleme yaptı",
                    message: "\"\($0.title)\" sırada",
                    iconName: "film",
                    timestamp: $0.createdAt
                )
            }
        
        let places = placeService.places
            .filter { $0.addedBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) yeni bir mekan önerdi",
                    message: $0.name,
                    iconName: "mappin.circle",
                    timestamp: $0.createdAt
                )
            }
        
        let songs = songService.songs
            .filter { $0.addedBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) şarkı listemize ekleme yaptı",
                    message: "\"\($0.title)\" - \($0.artist)",
                    iconName: "music.note.list",
                    timestamp: $0.createdAt
                )
            }
        
        let stories = storyService.partnerStories
            .filter { $0.createdBy == partnerId }
            .map {
                NotificationItem(
                    title: "\(partnerName) yeni bir story paylaştı",
                    message: $0.timeAgoText,
                    iconName: "camera.circle",
                    timestamp: $0.createdAt,
                    thumbnailURL: $0.thumbnailURL ?? $0.photoURL
                )
            }
        
        items.append(contentsOf: memories)
        items.append(contentsOf: photos)
        items.append(contentsOf: notes)
        items.append(contentsOf: plans)
        items.append(contentsOf: movies)
        items.append(contentsOf: places)
        items.append(contentsOf: songs)
        items.append(contentsOf: stories)
        
        return items
    }
    
    private var storyInteractionItems: [NotificationItem] {
        guard
            let currentUser = authService.currentUser,
            let relationship = relationshipService.currentRelationship,
            let currentUserId = currentUser.id else {
            return []
        }
        
        let partnerId = relationship.partnerId(for: currentUserId)
        let partnerName = relationship.partnerName(for: currentUserId)
        
        var items: [NotificationItem] = []
        
        let likedStories = storyService.userStories
            .compactMap { story -> NotificationItem? in
                guard story.isLikedBy(userId: partnerId) else { return nil }
                let likeDate = story.likeTimestamp(for: partnerId) ?? story.createdAt
                let timeString = likeDate.formatted(date: .omitted, time: .shortened)
                return NotificationItem(
                    title: "\(partnerName) story'ni beğendi",
                    message: "Beğenme zamanı: \(timeString)",
                    iconName: "heart.circle.fill",
                    timestamp: likeDate,
                    thumbnailURL: story.thumbnailURL ?? story.photoURL
                )
            }
       
        let storyReplies = messageService.messages
            .filter { $0.senderId == partnerId && $0.storyImageURL != nil }
            .map {
                let cleanedText = $0.text
                    .replacingOccurrences(of: "📸 Story'ye yanıt verdi\n", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let preview = cleanedText.isEmpty ? "Story'ne bir tepki bıraktı" : cleanedText
                return NotificationItem(
                    title: "\(partnerName) story'ne yanıt verdi",
                    message: preview,
                    iconName: "bubble.left.and.text.bubble.right.fill",
                    timestamp: $0.timestamp,
                    thumbnailURL: $0.storyImageURL
                )
            }
       
        items.append(contentsOf: likedStories)
        items.append(contentsOf: storyReplies)
        
        return items
    }
    
    private var surpriseItems: [NotificationItem] {
        guard
            let currentUser = authService.currentUser,
            let relationship = relationshipService.currentRelationship,
            let currentUserId = currentUser.id else {
            return []
        }
        
        let partnerId = relationship.partnerId(for: currentUserId)
        let partnerName = relationship.partnerName(for: currentUserId)
        
        return surpriseService.surprises
            .filter { $0.createdBy == partnerId }
            .map { surprise in
                let status: String
                if surprise.isManuallyHidden {
                    status = "Sürpriz hazır ama şu an gizli tutuluyor."
                } else if surprise.isOpened, let openedAt = surprise.openedAt {
                    status = "Sürprizi \(openedAt.formatted(date: .omitted, time: .shortened)) tarihinde açtın."
                } else if surprise.shouldReveal {
                    status = "Sürpriz hazır, açabilirsin!"
                } else {
                    let revealText = surprise.revealDate.formatted(date: .abbreviated, time: .shortened)
                    status = "Açılma zamanı: \(revealText)"
                }
                
                return NotificationItem(
                    title: "\(partnerName) sana sürpriz hazırladı",
                    message: status,
                    iconName: "gift.fill",
                    timestamp: surprise.createdAt,
                    thumbnailURL: surprise.photoURL
                )
            }
    }
    
    private var specialDayItems: [NotificationItem] {
        guard
            let currentUser = authService.currentUser,
            let relationship = relationshipService.currentRelationship,
            let currentUserId = currentUser.id else {
            return []
        }
        
        let partnerId = relationship.partnerId(for: currentUserId)
        let partnerName = relationship.partnerName(for: currentUserId)
        
        return specialDayService.specialDays
            .filter { $0.createdBy == partnerId }
            .map { day in
                let dateText = day.date.formatted(date: .long, time: .omitted)
                return NotificationItem(
                    title: "\(partnerName) özel gün ekledi",
                    message: "\"\(day.title)\" - \(dateText)",
                    iconName: "calendar.badge.heart",
                    timestamp: day.createdAt ?? day.date
                )
            }
    }
    
    private var secretVaultItems: [NotificationItem] {
        guard
            let currentUser = authService.currentUser,
            let relationship = relationshipService.currentRelationship,
            let currentUserId = currentUser.id else {
            return []
        }
        
        let partnerId = relationship.partnerId(for: currentUserId)
        let partnerName = relationship.partnerName(for: currentUserId)
        
        return secretVaultService.items
            .filter { $0.uploadedBy == partnerId }
            .map { item in
                let mediaType = item.isVideo ? "video" : "fotoğraf"
                let detail: String
                if let title = item.title, !title.isEmpty {
                    detail = "\"\(title)\" \(mediaType) ekledi."
                } else if let note = item.note, !note.isEmpty {
                    detail = "\(mediaType.capitalized) notu: \(note)"
                } else {
                    detail = "Gizli kasaya yeni bir \(mediaType) ekledi."
                }
                
                return NotificationItem(
                    title: "\(partnerName) gizli kasaya içerik ekledi",
                    message: detail,
                    iconName: item.isVideo ? "lock.rectangle.on.rectangle" : "lock.square.stack",
                    timestamp: item.createdAt,
                    thumbnailURL: item.thumbnailURL ?? (item.isVideo ? nil : item.downloadURL)
                )
            }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let item: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: item.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(item.timestamp.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let thumbnailURL = item.thumbnailURL {
                CachedAsyncImage(url: thumbnailURL, thumbnail: true) { image, _ in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Empty State

private struct EmptyNotificationState: View {
    let systemImage: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .regular))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Model

private struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let iconName: String
    let timestamp: Date
    let thumbnailURL: String?
    
    init(
        title: String,
        message: String,
        iconName: String,
        timestamp: Date,
        thumbnailURL: String? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.timestamp = timestamp
        self.thumbnailURL = thumbnailURL
    }
}
