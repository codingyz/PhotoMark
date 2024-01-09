import SwiftUI
import PhotosUI
import MobileCoreServices
import ImageIO

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        var onImagePicked: (UIImage) -> Void
        init(_ parent: ImagePicker, onImagePicked: @escaping (UIImage)->Void) {
            self.parent = parent
            self.onImagePicked = onImagePicked
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self?.addWatermark(to: uiImage, using: results.first!)
                        }
                    }
                }
            }
        }
        
        func addWatermark(to image: UIImage, using result: PHPickerResult) {
            let assetId = result.assetIdentifier
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId!], options: nil)
            guard let asset = assets.firstObject else { return }
            
            PHImageManager.default().requestImageData(for: asset, options: nil) { data, _, _, info in
                guard let data = data else { return }
                let source = CGImageSourceCreateWithData(data as CFData, nil)
                guard let metadata = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil) as? [CFString: Any] else { return }
                
                // Extract metadata details
                let TIFF = metadata["{TIFF}" as CFString] as? [String:Any]
                let cameraModel = TIFF!["Model" as String] as? String ?? "Unknown"
                let EXIF = metadata["{Exif}" as CFString] as? [String:Any]
                let aperture = EXIF![kCGImagePropertyExifFNumber as String] as? Double ?? 0.0
                let iso = (EXIF![kCGImagePropertyExifISOSpeedRatings as String] as? [NSNumber])?.first?.stringValue ?? "Unknown"
                let shutterSpeed = EXIF![kCGImagePropertyExifExposureTime as String] as? Double ?? 0.0
                let focalLength = EXIF![kCGImagePropertyExifFocalLenIn35mmFilm as String] as? Int ?? 0
                let takenTime = EXIF![kCGImagePropertyExifDateTimeOriginal as String] as? String ?? "Unknown"
                let location = self.getLocationString(from: asset)
                
                // Create watermark text
                let watermarkText = "Aperture: f\(aperture)   Shutter Speed: \(shutterSpeed)s   ISO: \(iso)   Focal Length: \(focalLength)mm\n\nDate: \(takenTime)\n\nLocation: \(location)\n\nCamera: \(cameraModel)"
                
                // let photoBasic = "Aperture: f\(aperture)   Shutter Speed: \(shutterSpeed)s   ISO: \(iso)"
                
                // Draw watermark
                let barHeight: CGFloat = 500 // Adjust as needed
                let imageSize = image.size
                let newImageSize = CGSize(width: imageSize.width, height: imageSize.height + barHeight)
                
                UIGraphicsBeginImageContext(newImageSize)
                
                // Draw original image
                image.draw(at: CGPoint.zero)
                
                // Draw bottom bar
                let barRect = CGRect(x: 0, y: imageSize.height, width: imageSize.width, height: barHeight)
                UIColor.white.setFill() // Choose your bar color
                UIRectFill(barRect)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 50), // Adjust font size as needed
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: UIColor.black
                ]
                
                let string = NSAttributedString(string: watermarkText, attributes: attrs)
                string.draw(in: CGRect(x: 0, y: imageSize.height + (barHeight - string.size().height) / 2, width: imageSize.width, height: string.size().height))
                
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Use newImage as needed
                DispatchQueue.main.async {
                    if let newImage = newImage {
                        self.onImagePicked(newImage)
                    }
                }
            }
        }
        
        private func getLocationString(from asset: PHAsset) -> String {
            guard let location = asset.location else { return "Unknown Location" }
            return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    }
}

