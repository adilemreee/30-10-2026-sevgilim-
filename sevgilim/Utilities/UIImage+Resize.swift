import UIKit

extension UIImage {
    /// Ölçüleri çok büyük görselleri belleği yormadan yükleyebilmek için yeniden boyutlandırır.
    /// - Parameter maxDimension: Piksel bazlı hedef uzun kenar sınırı.
    func preparedForStoryUpload(maxDimension: CGFloat = 1920) -> UIImage {
        let normalized = normalizedImage()
        let pixelWidth = normalized.size.width * normalized.scale
        let pixelHeight = normalized.size.height * normalized.scale
        let longestSide = max(pixelWidth, pixelHeight)

        guard longestSide > maxDimension else {
            return normalized
        }

        let resizeRatio = maxDimension / longestSide
        let targetPixelWidth = pixelWidth * resizeRatio
        let targetPixelHeight = pixelHeight * resizeRatio
        let targetSize = CGSize(width: targetPixelWidth, height: targetPixelHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func normalizedImage() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
