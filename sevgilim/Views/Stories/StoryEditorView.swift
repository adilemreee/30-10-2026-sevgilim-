import SwiftUI
import PencilKit

struct StoryEditorView: View {
    @Binding var image: UIImage?

    @Environment(\.dismiss) private var dismiss

    // PencilKit state
    @State private var drawing = PKDrawing()
    @State private var showsToolPicker = true

    // Ekranda fotoğrafın kapladığı gerçek dikdörtgen
    @State private var imageFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) FOTOĞRAF — oranlı göster ve gerçek çerçevesini ölç
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        // Alt araç çubuğu için yer bırak (ekranın üst ~%85'i)
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height * 0.85)
                        .overlay(
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        imageFrame = proxy.frame(in: .named("canvas"))
                                    }
                                    .onChange(of: proxy.size) { _ in
                                        imageFrame = proxy.frame(in: .named("canvas"))
                                    }
                            }
                        )
                        // Görüntüyü üstte konumlandır
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.40)
                }

                // 2) PENCILKIT CANVAS — tam fotoğrafın alanına oturur
                if imageFrame.width > 0 && imageFrame.height > 0 {
                    PencilCanvasView(
                        drawing: $drawing,
                        showsToolPicker: $showsToolPicker
                    )
                    .frame(width: imageFrame.width, height: imageFrame.height)
                    .position(x: imageFrame.midX, y: imageFrame.midY)
                    .clipped() // fotoğraf alanı dışına taşmaz
                }

                // 3) ÜST KAPAT (opsiyonel): Çarpı ile kapatma
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 12)

                        Spacer()
                    }
                    .padding(.top, 12)

                    Spacer()
                }

                // 4) ALT ARAÇ ÇUBUĞU — yalın: toolPicker, temizle, kaydet
                VStack {
                    Spacer()
                    HStack {
                        Spacer(minLength: 12)

                        // Apple'ın Tool Picker'ını aç/kapat
                        ToolbarButton(systemName: showsToolPicker ? "hand.draw.fill" : "hand.draw") {
                            showsToolPicker.toggle()
                        }

                        Spacer(minLength: 12)

                        // Tüm çizimi temizle
                        ToolbarButton(systemName: "trash") {
                            drawing = PKDrawing()
                        }

                        Spacer(minLength: 12)

                        // Kaydet ve çık
                        ToolbarButton(systemName: "checkmark") {
                            saveAndDismiss()
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.72))
                }
            }
            .coordinateSpace(name: "canvas")
            .ignoresSafeArea()
        }
    }

    // MARK: - KAYDET: fotoğraf + PencilKit çizimini birleştir
    private func saveAndDismiss() {
        guard let baseImage = image else {
            dismiss(); return
        }

        // imageFrame ölçülemediyse (uç durum), sadece fotoğrafı geri döndür
        guard imageFrame.width > 0, imageFrame.height > 0 else {
            dismiss(); return
        }

        // Canvas'ımız imageFrame boyutunda; PKDrawing'i fotoğraf piksele ölçekle
        let pointsPerPixelX = baseImage.size.width / imageFrame.width
        // Tek ölçek değeri yeterli (en-boy oranı scaledToFit ile korunuyor)
        let inkImage = drawing.image(
            from: CGRect(origin: .zero, size: imageFrame.size),
            scale: pointsPerPixelX
        )

        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        let composed = renderer.image { _ in
            // 1) Arka plan fotoğraf
            baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
            // 2) PencilKit çizimi (aynı piksel boyutunda)
            inkImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
        }

        image = composed
        dismiss()
    }
}

// MARK: - PencilKit Köprüsü
private struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var showsToolPicker: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let view = PKCanvasView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.drawing = drawing
        view.delegate = context.coordinator
        view.allowsFingerDrawing = true
        view.isScrollEnabled = false
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        return view
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        // ToolPicker'ı görünür yap/kap
        DispatchQueue.main.async {
            if let window = uiView.window, let picker = PKToolPicker.shared(for: window) {
                picker.setVisible(showsToolPicker, forFirstResponder: uiView)
                picker.addObserver(uiView)
                uiView.becomeFirstResponder()
            }
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        init(_ parent: PencilCanvasView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - UI Yardımcıları
private struct ToolbarButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
