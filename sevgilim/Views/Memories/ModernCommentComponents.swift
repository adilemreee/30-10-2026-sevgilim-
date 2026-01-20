import SwiftUI

// MARK: - Modern Comment Row
struct ModernCommentRow: View {
    let comment: Comment
    let isCurrentUser: Bool
    let profileImageURL: String?
    let onDelete: () -> Void
    let canDelete: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { Spacer() }
            
            if !isCurrentUser {
                // Avatar for partner
                if let profileImageURL = profileImageURL {
                    CachedAsyncImage(url: profileImageURL, thumbnail: true) { image, _ in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 1))
                    } placeholder: {
                        Circle()
                            .fill(themeManager.currentTheme.primaryColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(comment.userName.prefix(1)))
                                    .font(.caption.bold())
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                            }
                    }
                } else {
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String(comment.userName.prefix(1)))
                                .font(.caption.bold())
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Name (only for partner)
                if !isCurrentUser {
                    Text(comment.userName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                
                // Bubble
                Text(comment.text)
                    .font(.system(size: 15))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                isCurrentUser ?
                                AnyShapeStyle(themeManager.currentTheme.primaryColor) :
                                AnyShapeStyle(.ultraThinMaterial)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(isCurrentUser ? 0.2 : 0.5), lineWidth: 0.5)
                    )
                    // Context Menu for actions
                    .contextMenu {
                         if canDelete {
                             Button(role: .destructive, action: onDelete) {
                                 Label("Sil", systemImage: "trash")
                             }
                         }
                    }
                
                // Timestamp
                Text(comment.createdAt.timeAgo())
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 4)
            }
            
            if isCurrentUser {
                // Avatar for me
                Circle()
                    .fill(themeManager.currentTheme.primaryColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
            }
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Modern Comment Input
struct ModernCommentInput: View {
    @Binding var text: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                TextField("Yorum yaz...", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isFocused ? themeManager.currentTheme.primaryColor.opacity(0.5) : .white.opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isFocused ? themeManager.currentTheme.primaryColor.opacity(0.1) : .clear, radius: 5)
            
            Button(action: onSubmit) {
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            .scaleEffect(text.isEmpty ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: text.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
