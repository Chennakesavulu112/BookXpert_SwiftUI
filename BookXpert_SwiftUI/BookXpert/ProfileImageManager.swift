import SwiftUI
import CoreData
import PhotosUI

class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()
    
    @Published var profileImage: UIImage?
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingActionSheet = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    private let viewContext: NSManagedObjectContext
    
    private init() {
        self.viewContext = PersistenceController.shared.container.viewContext
        loadProfileImage()
    }
    
    func loadProfileImage() {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        if let profile = try? viewContext.fetch(request).first,
           let imageData = profile.profileImage {
            profileImage = UIImage(data: imageData)
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        viewContext.performAndWait {
            let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            let profile = try? viewContext.fetch(request).first ?? UserProfile(context: viewContext)
            
            profile?.profileImage = imageData
            try? viewContext.save()
            
            DispatchQueue.main.async {
                self.profileImage = image
            }
        }
    }
    
    func getInitialsImage(name: String) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let initials = name.prefix(1).uppercased()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = initials.size(withAttributes: attributes)
            let rect = CGRect(x: (size.width - textSize.width) / 2,
                            y: (size.height - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height)
            
            initials.draw(in: rect, withAttributes: attributes)
        }
    }
} 