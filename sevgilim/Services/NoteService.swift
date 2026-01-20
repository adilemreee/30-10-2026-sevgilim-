//
//  NoteService.swift
//  sevgilim
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class NoteService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func listenToNotes(relationshipId: String) {
        listener?.remove()
        isLoading = true
        
        // Optimized query with limit for better performance
        guard listener == nil else { return }
        
        isLoading = true
        
        listener = db.collection("notes")
            .whereField("relationshipId", isEqualTo: relationshipId)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50) // Limit to 50 notes
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to notes: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                let newNotes = documents.compactMap { doc -> Note? in
                    try? doc.data(as: Note.self)
                }
                
                // Client-side sorting: En yeni güncellenenler üstte
                let sortedNotes = newNotes.sorted { $0.updatedAt > $1.updatedAt }
                
                Task { @MainActor in
                    self.notes = sortedNotes
                    self.isLoading = false
                }
            }
    }
    
    func addNote(relationshipId: String, title: String, content: String, userId: String) async throws {
        let now = Date()
        let data: [String: Any] = [
            "relationshipId": relationshipId,
            "title": title,
            "content": content,
            "createdBy": userId,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]
        
        try await db.collection("notes").addDocument(data: data)
    }
    
    func updateNote(_ note: Note, title: String, content: String) async throws {
        guard let noteId = note.id else { return }
        
        let updates: [String: Any] = [
            "title": title,
            "content": content,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("notes").document(noteId).updateData(updates)
    }
    
    func deleteNote(_ note: Note) async throws {
        guard let noteId = note.id else { return }
        try await db.collection("notes").document(noteId).delete()
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        listener?.remove()
    }
}
