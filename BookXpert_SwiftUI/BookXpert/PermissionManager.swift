import SwiftUI
import AVFoundation
import Photos

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var cameraPermission: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryPermission: PHAuthorizationStatus = .notDetermined
    
    private init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryPermission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestCameraPermission() async -> Bool {
        return await AVCaptureDevice.requestAccess(for: .video)
    }
    
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    var hasCameraPermission: Bool {
        return cameraPermission == .authorized
    }
    
    var hasPhotoLibraryPermission: Bool {
        return photoLibraryPermission == .authorized
    }
} 