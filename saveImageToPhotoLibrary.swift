import UIKit
import Photos

func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Error?) -> Void) {
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            completion(nil)
        } else {
            completion(NSError(domain: "com.yourdomain.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unauthorized access to photo library"]))
        }
    }
}

func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
        // We got back an error!
        print(error.localizedDescription)
    } else {
        print("Image saved successfully")
    }
}
