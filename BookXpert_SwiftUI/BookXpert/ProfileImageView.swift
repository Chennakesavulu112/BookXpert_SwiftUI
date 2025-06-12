import SwiftUI
import PhotosUI

struct ProfileImageView: View {
    @StateObject private var imageManager = ProfileImageManager.shared
    let name: String
    
    var body: some View {
        Group {
            if let image = imageManager.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(uiImage: imageManager.getInitialsImage(name: name))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .onTapGesture {
            imageManager.showingActionSheet = true
        }
        .confirmationDialog("Choose Image Source", isPresented: $imageManager.showingActionSheet) {
            Button("Camera") {
                imageManager.sourceType = .camera
                imageManager.showingImagePicker = true
            }
            Button("Photo Library") {
                imageManager.sourceType = .photoLibrary
                imageManager.showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $imageManager.showingImagePicker) {
            ProfileImagePicker(image: Binding(
                get: { imageManager.profileImage ?? imageManager.getInitialsImage(name: name) },
                set: { newImage in
                    imageManager.saveProfileImage(newImage)
                }
            ), sourceType: imageManager.sourceType)
        }
    }
}

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) private var presentationMode
    
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
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
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