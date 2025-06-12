import SwiftUI
import UIKit
import Photos

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    @StateObject private var permissionManager = PermissionManager.shared
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Extension to handle permissions
extension ImagePicker {
    static func checkAndRequestPermissions(sourceType: UIImagePickerController.SourceType) async -> Bool {
        let permissionManager = PermissionManager.shared
        
        switch sourceType {
        case .camera:
            if !permissionManager.hasCameraPermission {
                return await permissionManager.requestCameraPermission()
            }
            return true
            
        case .photoLibrary:
            if !permissionManager.hasPhotoLibraryPermission {
                let status = await permissionManager.requestPhotoLibraryPermission()
                return status == .authorized
            }
            return true
            
        default:
            return false
        }
    }
} 