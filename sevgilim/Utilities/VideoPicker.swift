//
//  VideoPicker.swift
//  sevgilim
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .automatic
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: VideoPicker
        private let fileManager = FileManager.default
        
        init(parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
                return
            }
            
            let supportedTypes: [UTType] = [.movie, .video, .mpeg4Movie]
            guard let matchedType = supportedTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
                return
            }
            
            provider.loadFileRepresentation(forTypeIdentifier: matchedType.identifier) { url, error in
                guard let sourceURL = url, error == nil else {
                    if let error {
                        print("❌ Video picker load error: \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        self.parent.dismiss()
                    }
                    return
                }
                
                let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension.lowercased()
                let tempURL = self.fileManager.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
                
                do {
                    if self.fileManager.fileExists(atPath: tempURL.path) {
                        try self.fileManager.removeItem(at: tempURL)
                    }
                    try self.fileManager.copyItem(at: sourceURL, to: tempURL)
                    
                    DispatchQueue.main.async {
                        self.parent.videoURL = tempURL
                        self.parent.dismiss()
                    }
                } catch {
                    print("❌ Video picker copy error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.parent.dismiss()
                    }
                }
            }
        }
    }
}
